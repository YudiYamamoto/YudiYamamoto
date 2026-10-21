#!/usr/bin/env bash
# Renders an SVG card with this month's commits, pull requests and repositories.
# Needs GH_TOKEN: a PAT with `repo` scope also counts private repositories;
# the default GITHUB_TOKEN only sees public ones.
# Usage: monthly-activity.sh <github-user> [output.svg]
set -euo pipefail

user="${1:?usage: monthly-activity.sh <github-user> [output.svg]}"
out="${2:-dist/monthly-activity.svg}"

export TZ=America/Sao_Paulo LC_ALL=C
since=$(date +%Y-%m-01)
month=$(date +'%B %Y')
updated=$(date +'%b %-d, %Y')

commits=$(gh api "search/commits?q=author:$user+author-date:>=$since&per_page=1" --jq .total_count)
prs=$(gh api "search/issues?q=type:pr+author:$user+created:>=$since&per_page=1" --jq .total_count)
# ponytail: search returns at most 1000 results, so past 1000 commits/month the repository count undercounts
repos=$(gh api --paginate "search/commits?q=author:$user+author-date:>=$since&per_page=100" \
  --jq '.items[].repository.full_name' | sort -u | wc -l | tr -d ' ')

mkdir -p "$(dirname "$out")"
cat > "$out" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="495" height="195" viewBox="0 0 495 195" role="img" aria-labelledby="title">
  <title id="title">$month: $commits commits, $prs pull requests, $repos repositories</title>
  <style>
    text { font-family: 'Segoe UI', Ubuntu, 'Helvetica Neue', Sans-Serif; text-anchor: middle; }
    .heading { font-size: 16px; font-weight: 600; fill: #2F6BFF; }
    .value { font-size: 30px; font-weight: 700; fill: #FFFFFF; }
    .label { font-size: 14px; fill: #FFFFFF; }
    .footer { font-size: 11px; fill: #8B949E; }
  </style>
  <rect width="495" height="195" rx="4.5" fill="#000000"/>
  <text x="247.5" y="36" class="heading">$month</text>
  <line x1="165" y1="58" x2="165" y2="150" stroke="#0038F7"/>
  <line x1="330" y1="58" x2="330" y2="150" stroke="#0038F7"/>
  <text x="82.5" y="105" class="value">$commits</text>
  <text x="82.5" y="135" class="label">Commits</text>
  <text x="247.5" y="105" class="value">$prs</text>
  <text x="247.5" y="135" class="label">Pull requests</text>
  <text x="412.5" y="105" class="value">$repos</text>
  <text x="412.5" y="135" class="label">Repositories</text>
  <text x="247.5" y="180" class="footer">Updated $updated</text>
</svg>
SVG
