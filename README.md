# :zap: Timesheet

> Automatically generate your timesheet using Github API :octocat:

## :gear: Setup

1. Clone project

    ```sh
    git clone https://github.com/vivekmiyani/timesheet.git ~/timesheet
    cd ~/timesheet
    ```

2. Install dependency

    ```sh
    gem install octokit
    ```

3. Create projects.yml

    ```sh
    cp projects.yml.example projects.yml
    ```

4. Configure project groups in projects.yml

    - Create and update github token (with access to `user` and `repo` scopes)

## :sparkles: Usage

Generate your today's timesheet for any project group:

```sh
~/timesheet/work.rb $(date '+%Y-%m-%d') <friendly_name>
```

Or even for any date:

```sh
~/timesheet/work.rb 2023-01-01 <friendly_name>
```

## :dart: Todo

- [ ] Handle response pagination
- [ ] Handle branch without pull request
