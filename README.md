# :zap: Timesheet

> Automatically generate your timesheet using Github API :octocat:

## :gear: Setup

1. Clone project

   ```sh
   git clone https://github.com/vivekmiyani/timesheet.git ~/timesheet
   ```

2. Install dependency

   ```sh
   gem install faraday
   ```

3. Generate Github API token

   - Open [Generate new token (classic)](https://github.com/settings/tokens/new)
   - Set Expiration to **Never**
   - Select scopes: `repo` and `user`
   - Click **Generate** and copy the token

4. Save the token to `~/.timesheet-token` in your home folder.

## :sparkles: Usage

Generate your today's timesheet:

```sh
~/timesheet/work.rb $(date '+%Y-%m-%d')
```

Or for any date:

```sh
~/timesheet/work.rb 2023-01-01
```
