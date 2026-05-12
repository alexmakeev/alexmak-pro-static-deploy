# Hero photo — pipeline инструкция

Эта инструкция нужна когда захочется заменить hero на новую фотку Alex
(или прогнать любую другую вертикальную портретную фотку под layout сайта).

## Параметры финального файла

- **hero-rooftop.webp**: WebP, quality=80, method=6, ~128 KB
- **hero-rooftop.png**: PNG RGBA, master (~1.8 MB)
- **Размер**: 975 × 2560 px
- **Аспект**: 0.381 (975 / 2560) — ОБЯЗАТЕЛЬНЫЙ, layout сайта (Hero, Profile, About sections) полагается на узкую высокую фотку этого аспекта. Сменить аспект — сломаются паддинги и пропорции страницы.

## Pipeline (как сделать новую версию из исходного фото)

### Требования к исходнику

- **Поза**: 3/4 поворот, рука в кармане, deliberate (как у текущей фотки)
- **Кадрировка исходника**: от макушки до колен/бёдер (видимая часть силуэта будет от макушки до бёдер — низ обрежется автоматически)
- **Фон**: любой, будет вырезан через rembg birefnet
- **Разрешение**: минимум 2000 × 3000 px, желательно 2296 × 3072 или больше
- **Источник света**: реальный (rooftop с естественным светом — best). Студийная подсветка тоже OK.

### Шаги

```bash
# 0. Положить исходник в materials/photos/ (gitignored — не коммитим оригиналы)
SRC=~/plan/materials/photos/2026-MM-DD-source.png   # или .jpg

# 1. Прогон pipeline (rembg + binary_fill_holes + edge fill bottom + RGB restore)
cd ~/plan
python scripts/process_hero.py \
  --input "$SRC" \
  --outdir sandboxes/hero-new \
  --current website/public/images/hero-rooftop.webp
  # Default: --fill-edges bottom (закрашивает трапецию между ног)
  # Для фоток с реальным светлым просветом между ног: --no-fill-edges

# Артефакты: sandboxes/hero-new/02c-filled-correct-rgb.png (RGBA cutout, full res)

# 2. Crop под аспект 0.381 (975 × 2560)
# Утилита автоматически центрирует на фигуре через alpha bbox.
# Для head-aligned crop (когда лицо смещено относительно тела) —
# вычислить x-center головы и передать --x-center.
python scripts/crop_to_aspect.py \
  --input  sandboxes/hero-new/02c-filled-correct-rgb.png \
  --output sandboxes/hero-new/cropped.png \
  --target-aspect 0.381 \
  --target-width 975 \
  --target-height 2560
  # Если crop не совпал с prod — добавить --x-center N
  # Найти N: проверить голову в исходнике (например через grid overlay),
  # X-координата центра головы — это N.

# 3. Визуальная проверка кадрировки перед заменой prod
# Сравнить crop с архивным prod side-by-side (на нейтральном фоне).
# Если фигура смещена относительно ожидаемой позиции — повторить шаг 2 с --x-center.

# 4. Конверсия в webp (target ~130 KB → quality=80)
cwebp -q 80 -m 6 sandboxes/hero-new/cropped.png -o sandboxes/hero-new/hero-rooftop.webp
# либо Python:
python -c "from PIL import Image; \
  Image.open('sandboxes/hero-new/cropped.png').save( \
    'sandboxes/hero-new/hero-rooftop.webp', 'WEBP', quality=80, method=6)"

# 5. Архивировать ТЕКУЩУЮ версию (перед заменой!)
NEXT_V=$(ls -d website/public/images/archive-hero-v* 2>/dev/null \
  | sed 's/.*v//' | sort -n | tail -1 | awk '{print $1+1}')
mkdir -p "website/public/images/archive-hero-v${NEXT_V}"
mv website/public/images/hero-rooftop.png \
   website/public/images/hero-rooftop.webp \
   "website/public/images/archive-hero-v${NEXT_V}/"

# 6. Положить новую версию
cp sandboxes/hero-new/cropped.png        website/public/images/hero-rooftop.png
cp sandboxes/hero-new/hero-rooftop.webp  website/public/images/hero-rooftop.webp

# 7. Сборка + deploy
cd ~/plan/website && npm run build
rsync -av --delete ~/plan/website/dist/ ~/alexmak-pro-static-deploy/dist/
cd ~/alexmak-pro-static-deploy
git add -A && git commit -m "Deploy: hero vN" && git push origin main
```

## Текущий релиз (v2 — 2026-05-12)

- **Source**: `.telegram/muzhchina-starshe-predprinimatel-v2-w2296px-h3072px.png` (2296 × 3072, lицо «постарше», NYC rooftop)
- **Дата**: 2026-05-12
- **Crop в координатах исходника**: x = 314..1484 (width 1170), y = 0..3072 (height 3072)
- **Downscale**: 1170 × 3072 → 975 × 2560 (Lanczos)
- **Финальный webp размер**: 128.5 KB (quality=80, method=6)
- **Особенности pipeline**:
  - rembg birefnet alpha_matting (fg=240, bg=10, erode=5)
  - binary_fill_holes — внутренние дырки в альфе
  - fill_edge_open_holes (edges=bottom, border=50) — закрытие трапеции между ног
  - RGB восстановлен из source для всех заполненных пикселей
  - alpha forced=255 внутри binary mask (уплотнение anti-aliasing для чистой границы)
- **Кадрировка**: head-aligned (x_center=898 в crop) — голова в той же позиции что v1 для бит-в-бит совпадения с layout-ом. Автоматический alpha-bbox center (833) даёт смещение фигуры влево на ~33 px после downscale, поэтому use `--x-center 898` для воспроизведения.

## Архив предыдущих версий

| Версия | Папка | Дата | Особенности |
|--------|-------|------|-------------|
| v1 | `archive-hero-v1/` | до 2026-05-12 | Моложавое лицо, тот же NYC rooftop background. Состоит из `hero-rooftop.v9x24-pass6.webp` (последний pass), `hero-rooftop.png`, ряд промежуточных. Crop эталон для v2 head-alignment. |
| v2 | (текущий) | 2026-05-12 | Лицо «постарше», новый источник 2296×3072 |

## Контрольные проверки после замены

```bash
# 1. Локальный preview
cd ~/plan/website && npm run dev
# открыть http://localhost:5173, проверить hero на index page

# 2. После deploy на dev
curl -I https://alexmak.am32.oneln.ru/images/hero-rooftop.webp
# content-length должен совпадать с локальным file size

# 3. Скриншот на mac viewport (1440×900)
# - hero высота ~900 px (узкий высокий первый экран — корректно)
# - силуэт чистый, без прозрачных дырок в торсе/руках/ногах
# - голова на той же высоте что v1 (визуально)

# 4. Mobile (375×667) и tablet (768×1024) — фигура не перекрывает текст
```

## Troubleshooting

- **«Фигура слишком вправо / влево» после crop_to_aspect**
  Использовать `--x-center` явно. Найти X через grid overlay (`scripts/process_hero.py` создаёт промежуточные с grid).
- **«Hero на сайте слишком широкий/низкий» после deploy**
  Скорее всего съехал аспект. Проверить `from PIL import Image; print(Image.open('website/public/images/hero-rooftop.webp').size)` — должно быть `(975, 2560)`.
- **«Силуэт с дырками в торсе»**
  process_hero.py пропустил binary_fill_holes — повторить с `--fill-iterations 2` или вручную в Photoshop/Krita.
- **«Webp размер > 200 KB»**
  Снизить quality до 75 или 72. Ниже 70 не рекомендуется — артефакты в волосах и ткани пиджака.
