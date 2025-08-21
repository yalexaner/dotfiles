## Code Commenting Guidelines

- always write comments with lowercase letters, if you are writing the kdoc or javadoc then you might use the uppercase letter for the main information or by following the kdoc and javadoc guidelines

## Commit Message Generation Rules

- when generating commit messages, strictly follow the Conventional Commits specification
- start every commit message with a lowercase standardized type (e.g., feat, fix, chore, refactor)
- optionally include a lowercase scope in parentheses
- use a colon after the type (and optional scope)
- write a concise, lowercase description not exceeding 72 characters (recommended 50)
- if additional explanation is needed, generate a list with each line starting with a dash and a space, led by a lowercase, simple-verb sentence
- when asked about creating a commit message, generate the message and use the command "jj desc -m" with the message in parentheses
- create a markdown file for the commit message with the main message first, followed by a description list using dashes
- assume the provided patch is valid and avoid unnecessary clarifying questions

## Git Operations

- when doing any operations with git first try to use git.exe as you are working from wsl

## JJ Operations

- when using jj command try to use jj.exe first the same way as with git command