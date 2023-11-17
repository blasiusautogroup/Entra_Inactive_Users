name: Check Inactive Users on Ubuntu

on:
  schedule:
    - cron: '15 22 * * *' # Runs every day at 22:15 UTC
  workflow_dispatch:
  push:
    branches: [main]

jobs:
  check-inactive-users:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository code
        uses: actions/checkout@v3

      - name: Setup PowerShell module cache
        uses: actions/cache@v3
        with:
          path: "~/.local/share/powershell/Modules"
          key: ${{ runner.os }}-SqlServer-PSScriptAnalyzer

      - name: Install MSAL.PS Module
        if: steps.cache.outputs.cache-hit != 'true'
        run: |
          Set-PSRepository PSGallery -InstallationPolicy Trusted
          Install-Module MSAL.PS -Force -Scope CurrentUser -Verbose
        shell: pwsh

      - name: Run PowerShell script
        env:
          CLIENT: ${{ secrets.CLIENT }}
          SECRET: ${{ secrets.SECRET }}
          TENANT: ${{ secrets.TENANT }}
          GROUP_OBJECT_ID: ${{ secrets.GROUP_OBJECT_ID }}
          TEAM_WEBHOOK_URL: ${{ secrets.TEAM_WEBHOOK_URL }}
        run: |
          pwsh -File ./inactiveusers.ps1
        shell: pwsh