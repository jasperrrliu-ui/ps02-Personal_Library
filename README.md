# Personal Book Manager

A small Bash command-line application for managing a personal library and generating book recommendations.

## Demo

[Watch the narrated demo video](demo-video.mp4)

## Run the app

This project requires Bash and [Gum](https://github.com/charmbracelet/gum).

On macOS, install Gum with Homebrew:

```bash
brew install gum
```

On Windows, install Gum with Winget and run the project from Git Bash:

```powershell
winget install charmbracelet.gum
```

Then, from the project directory on macOS, Linux, or Git Bash for Windows:

```bash
bash app.sh
```

## Features

- Browse, add, search, and update books in a personal library.
- Enrich a uniquely matched title with local metadata.
- Update reading status and rating using a title alone when it is unique.
- Generate five recommendations through three parallel strategies.

## Architecture

The application follows this flow:

```text
UI → Workflows → Book / Recommendation Components → Data Layer → Storage
```

`app.sh` is the entry point. It starts `ui/main_menu.sh`, which uses Gum to collect the user's action. The app then routes the selected action to either the library screen or the recommendations screen.

```text
app.sh
  └─ ui/main_menu.sh
       ├─ ui/library_screen.sh
       │    └─ workflows/manage_library.sh
       │         ├─ books/fetch_book_metadata.sh
       │         ├─ books/search_books.sh
       │         └─ data/book_database.sh → data/books.csv
       └─ ui/recommendations_screen.sh
            └─ workflows/get_recommendations.sh
                 ├─ recommend_from_history.sh
                 ├─ recommend_from_interests.sh
                 ├─ recommend_for_discovery.sh
                 └─ refine_recommendations.sh
```

The UI files only collect input and display output. `manage_library.sh` coordinates browse, add, search, status updates, and rating updates. `book_database.sh` is the only script that directly reads or writes `books.csv`, so the storage logic stays in one place.

The recommendation workflow uses three independent strategies. The history strategy uses books that I finished. The interest strategy matches `interests.txt` against the `genre` and `themes` fields in `book_metadata.csv`. The discovery strategy selects a book outside the genres I have finished. `get_recommendations.sh` starts all three scripts concurrently with `&`, stores their process IDs with `$!`, waits with `wait`, combines the output, and pipes it into `refine_recommendations.sh`. The refiner removes duplicates and books already in my library, then returns two history recommendations, two interest recommendations, and one discovery recommendation.

## Personalization

`data/books.csv` is my personal library: it stores title, author, genre, year, reading status, rating, and an optional link. It reflects my interest in mystery fiction, classic literature, philosophy, and books about human behavior.

`data/book_metadata.csv` is a separate local reference catalog. It includes basic book metadata plus a `themes` column. `data/interests.txt` contains my interests, including modern crime fiction, human nature, psychological motives, moral ambiguity, literary mystery, and contemporary fiction. The interest recommendation strategy directly matches those interests against each candidate book's genre and themes. The discovery strategy deliberately selects a book outside the genres I have finished.
