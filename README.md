# Animal Tracking in Conservation Biology — 2026-2027

Course material for **Animal Tracking in Conservation Biology**, MSc *Biologia
Ambientale*, University of Rome Tor Vergata. 2 CFU, 8 sessions × 2 hours
(~45 minutes of theory, ~75 minutes of R each).

📖 **Website: <https://giulianocolosimo.github.io/animtrack-2627/>**

Built with [Quarto](https://quarto.org/): reveal.js slides with interactive
pop-up quizzes, R practicals with collapsible solutions, and the datasets.

## Layout

```
.
├── _quarto.yml           # site config: navbar, sidebar, formats
├── index.qmd             # home
├── calendar.qmd          # dates, in the calendR style of previous sites
├── syllabus.qmd          # outcomes, the eight sessions, assessment
├── setup.qmd             # R / RStudio / package installation
├── data.qmd              # dataset documentation
├── resources.qmd         # reading list and links
├── assets/
│   ├── quiz.html         # the pop-up quiz engine (JS)
│   ├── quiz.css          # quiz styling
│   ├── theme.scss        # website theme (light)
│   ├── theme-dark.scss   # website theme (dark)
│   ├── theme-slides.scss # reveal.js slide theme
│   └── figures/
├── classes/
│   └── class-01 … class-08/      # one folder per session
│       ├── slides.qmd            # reveal.js deck with embedded quizzes
│       └── exercise.qmd          # R practical with solutions
├── R/
│   ├── simulators.R              # random walks + the "ground-truth" animals (Sessions 5-7)
│   └── hr_ground_truth.R         # replicate home-range study → data/hr_ground_truth.csv
├── data/                 # tracks (gzipped CSV), Kruger rasters, simulation results
├── _freeze/              # cached chunk results — committed on purpose
└── docs/                 # rendered site — committed, served by GitHub Pages
```

## Building the site

```bash
quarto render          # whole site into docs/
quarto preview         # live preview while editing
quarto render classes/class-01/slides.qmd   # just one deck
```

`execute: freeze: auto` caches R results in `_freeze/`. Commit that folder:
it means the site can be rebuilt (and checked on CI) without R or any of the
spatial system libraries installed.

## Publishing on GitHub Pages

One-time setup:

1. Create the repository and push:
   ```bash
   git remote add origin https://github.com/GiulianoColosimo/animtrack-2627.git
   git push -u origin main
   ```
2. On GitHub: **Settings → Pages → Build and deployment**
   Source = *Deploy from a branch*, Branch = `main`, Folder = **`/docs`**.

After that, publishing is just:

```bash
quarto render && git add -A && git commit -m "Update" && git push
```

The site goes live at `https://<user>.github.io/animtrack-2627/` within a
minute or two.

> If you rename the repository, update `site-url` and `repo-url` in
> `_quarto.yml` and the links in `README.md` and `setup.qmd`.

## Writing a pop-up quiz

Anywhere in a slide deck or a practical page:

```markdown
::: {.quiz}
Which of these is a *fix*?

- [ ] A collar attached to an animal
- [x] One timestamped location estimate
- [ ] The area an animal uses in a year

::: {.quiz-feedback}
A fix is a single location estimate with a timestamp attached.
:::
:::
```

`[x]` marks the correct answer — several are allowed. Clicking any option
reveals the correct answer(s) and the feedback box, and an *"ask again"*
button resets it so you can rerun the question with the next cohort.

## Slide shortcuts (reveal.js)

| Key | |
|:--|:--|
| `F` | fullscreen |
| `S` | speaker view with notes and timer |
| `E` | print / PDF layout (then Ctrl-P → Save as PDF) |
| `O` or `Esc` | slide overview |
| `B` | blank the screen |
| `?` | all shortcuts |

## Datasets

Three Movebank studies, redistributed for teaching — see
[`data.qmd`](data.qmd) for full attribution:

- `data/buffalo_kruger.csv.gz` — 6 African buffalo, Kruger NP, GPS, 2005–2006
- `data/bat_safi.csv.gz` — 17 parti-coloured bats, Switzerland, VHF, 2002–2003
- `data/vulture_leo.csv.gz` — 1 turkey vulture, 6 years of migration, GPS
- `data/kruger_*.tif` — MODIS NDVI (2005), elevation, land cover, precipitation
- Package data used in the practicals: `amt::amt_fisher` (NY fishers) and
  `ctmm::gazelle` (Mongolian gazelles)

## Licence

Text, slides and figures: [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).
Code: MIT. Datasets remain under their original Movebank licences.

© 2026 Giuliano Colosimo
