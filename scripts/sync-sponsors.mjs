#!/usr/bin/env node
// Fetches GitHub Sponsors data for The-Andb and writes docs/sponsors.json,
// then updates the marker blocks in README.md and SPONSORS.md.
//
// Requires SPONSORS_TOKEN env var: a token (classic PAT or fine-grained) with
// `read:org` + sponsors read access, since GITHUB_TOKEN cannot read Sponsors data.

import { writeFileSync, readFileSync, mkdirSync } from 'node:fs';
import { dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ORG = 'The-Andb';
const TOKEN = process.env.SPONSORS_TOKEN;
const ROOT = fileURLToPath(new URL('..', import.meta.url));

if (!TOKEN) {
  console.error('Missing SPONSORS_TOKEN env var — cannot query the Sponsors GraphQL API.');
  process.exit(1);
}

const QUERY = /* GraphQL */ `
  query ($login: String!, $cursor: String) {
    organization(login: $login) {
      sponsorshipsAsMaintainer(first: 100, after: $cursor, includePrivate: false) {
        pageInfo {
          hasNextPage
          endCursor
        }
        nodes {
          createdAt
          privacyLevel
          tier {
            monthlyPriceInDollars
            isOneTime
          }
          sponsorEntity {
            __typename
            ... on User {
              login
              name
              avatarUrl
              url
            }
            ... on Organization {
              login
              name
              avatarUrl
              url
            }
          }
        }
      }
    }
  }
`;

async function graphql(query, variables) {
  const res = await fetch('https://api.github.com/graphql', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${TOKEN}`,
      'Content-Type': 'application/json',
      'User-Agent': 'the-andb-sponsors-sync',
    },
    body: JSON.stringify({ query, variables }),
  });
  if (!res.ok) {
    throw new Error(`GraphQL request failed: ${res.status} ${res.statusText}\n${await res.text()}`);
  }
  const json = await res.json();
  if (json.errors) {
    throw new Error(`GraphQL errors: ${JSON.stringify(json.errors, null, 2)}`);
  }
  return json.data;
}

async function fetchAllSponsorships() {
  const all = [];
  let cursor = null;
  for (;;) {
    const data = await graphql(QUERY, { login: ORG, cursor });
    const conn = data.organization.sponsorshipsAsMaintainer;
    all.push(...conn.nodes);
    if (!conn.pageInfo.hasNextPage) break;
    cursor = conn.pageInfo.endCursor;
  }
  return all;
}

function buildSummary(sponsorships) {
  const active = sponsorships.filter((s) => s.sponsorEntity);

  const monthly = active.filter((s) => !s.tier?.isOneTime);
  const monthlyTotal = monthly.reduce((sum, s) => sum + (s.tier?.monthlyPriceInDollars ?? 0), 0);

  const sponsors = active
    .map((s) => ({
      login: s.sponsorEntity.login,
      name: s.sponsorEntity.name || s.sponsorEntity.login,
      avatarUrl: s.sponsorEntity.avatarUrl,
      url: s.sponsorEntity.url,
      type: s.sponsorEntity.__typename,
      monthlyPriceInDollars: s.tier?.monthlyPriceInDollars ?? 0,
      isOneTime: Boolean(s.tier?.isOneTime),
      since: s.createdAt,
    }))
    .sort((a, b) => b.monthlyPriceInDollars - a.monthlyPriceInDollars);

  return {
    generatedAt: new Date().toISOString(),
    sponsorCount: sponsors.length,
    monthlyTotalDollars: monthlyTotal,
    sponsors,
    topSponsors: sponsors.filter((s) => s.monthlyPriceInDollars > 0).slice(0, 10),
  };
}

function renderMarkdownList(topSponsors) {
  if (topSponsors.length === 0) {
    return '_No sponsors yet — [be the first →](https://github.com/sponsors/The-Andb)_';
  }
  return topSponsors
    .map((s) => `[<img src="${s.avatarUrl}" width="48" height="48" alt="${s.login}" title="${s.name}" />](${s.url})`)
    .join('\n');
}

function renderBadge(summary) {
  const label = `${summary.sponsorCount} sponsor${summary.sponsorCount === 1 ? '' : 's'} · $${summary.monthlyTotalDollars}/mo`;
  const encoded = encodeURIComponent(label);
  return `[![Sponsors](https://img.shields.io/badge/Sponsors-${encoded}-ff69b4?style=for-the-badge&logo=githubsponsors)](https://github.com/sponsors/The-Andb)`;
}

function updateMarkerBlock(filePath, marker, content) {
  const start = `<!-- ${marker}:start -->`;
  const end = `<!-- ${marker}:end -->`;
  const source = readFileSync(filePath, 'utf8');
  const startIdx = source.indexOf(start);
  const endIdx = source.indexOf(end);
  if (startIdx === -1 || endIdx === -1) {
    console.warn(`Marker "${marker}" not found in ${filePath} — skipping.`);
    return;
  }
  const before = source.slice(0, startIdx + start.length);
  const after = source.slice(endIdx);
  const next = `${before}\n${content}\n${after}`;
  writeFileSync(filePath, next);
}

async function main() {
  const sponsorships = await fetchAllSponsorships();
  const summary = buildSummary(sponsorships);

  const jsonPath = `${ROOT}/docs/sponsors.json`;
  mkdirSync(dirname(jsonPath), { recursive: true });
  writeFileSync(jsonPath, `${JSON.stringify(summary, null, 2)}\n`);

  const badge = renderBadge(summary);
  const list = renderMarkdownList(summary.topSponsors);

  updateMarkerBlock(`${ROOT}/README.md`, 'sponsors', `${badge}\n\n${list}`);
  updateMarkerBlock(`${ROOT}/SPONSORS.md`, 'sponsors', `${badge}\n\n### Top Sponsors\n\n${list}`);

  console.log(`Synced ${summary.sponsorCount} sponsors, $${summary.monthlyTotalDollars}/mo total.`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
