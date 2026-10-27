// Copies what the site shows from the rest of the repo, so it never goes
// stale against the app: screenshots, widget photos, the Studio template
// pack, the brand icon, the CHANGELOG and the in-app privacy policy.
// Runs before `dev` and `build`; everything it writes is gitignored.
import { copyFileSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const site = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const repo = resolve(site, "..");
const publicOut = join(site, "public", "content");
const dataOut = join(site, "src", "content", "generated");

function copy(from, to) {
  mkdirSync(dirname(to), { recursive: true });
  copyFileSync(join(repo, from), to);
}

rmSync(publicOut, { recursive: true, force: true });
rmSync(dataOut, { recursive: true, force: true });
mkdirSync(dataOut, { recursive: true });

// App screenshots (600 × 1303).
for (const file of readdirSync(join(repo, "screenshots/app"))) {
  if (file.endsWith(".png")) copy(`screenshots/app/${file}`, join(publicOut, "app", file));
}

// Widget photos.
for (const file of ["built-ios-today-large.jpg", "built-android-light.jpg"]) {
  copy(`docs/design/home-widgets-v4/${file}`, join(publicOut, "widgets", file));
}

// Brand icon.
copy("apps/myanmar_calendar/assets/branding/app_icon_1024.png", join(publicOut, "brand", "icon.png"));

// Studio template pack: previews and both downloads per design.
const designs = JSON.parse(readFileSync(join(repo, "docs/studio-templates/designs.json"), "utf8"));
for (const design of designs) {
  for (const key of ["project", "template", "preview"]) {
    copy(`docs/studio-templates/${design[key]}`, join(publicOut, "templates", design[key]));
  }
  // A PNG's width and height sit in its IHDR chunk, bytes 16–23.
  const png = readFileSync(join(repo, "docs/studio-templates", design.preview));
  design.previewWidth = png.readUInt32BE(16);
  design.previewHeight = png.readUInt32BE(20);
  design.year = Number(design.project.match(/-(\d{4})\.mmcstudio$/)?.[1]) || null;
}
writeFileSync(join(dataOut, "templates.json"), JSON.stringify(designs, null, 2));

// CHANGELOG.md: "## [2.3.1+232] - 2026-10-27" headings and "- " bullets.
const releases = [];
for (const line of readFileSync(join(repo, "CHANGELOG.md"), "utf8").split("\n")) {
  const heading = line.match(/^## \[(\d+\.\d+\.\d+)(?:\+(\d+))?\]\s*-\s*(\d{4}-\d{2}-\d{2})/);
  if (heading) {
    releases.push({ version: heading[1], build: heading[2] ?? null, date: heading[3], notes: [] });
    continue;
  }
  const release = releases.at(-1);
  if (!release) continue;
  const bullet = line.match(/^(\s*)- (.*)$/);
  if (bullet) {
    release.notes.push({ text: bullet[2].trim(), nested: bullet[1].length > 0 });
  } else if (line.trim() && release.notes.length) {
    // A wrapped bullet continues the previous one.
    release.notes.at(-1).text += ` ${line.trim()}`;
  }
}
writeFileSync(join(dataOut, "releases.json"), JSON.stringify(releases, null, 2));

// The privacy policy the app shows (AppConstants.privacyPolicyMarkdown).
const constants = readFileSync(join(repo, "packages/shared/core/lib/src/constants/app_constants.dart"), "utf8");
const policy = constants.match(/privacyPolicyMarkdown\s*=\s*'''([\s\S]*?)'''/);
if (!policy) throw new Error("privacyPolicyMarkdown not found in app_constants.dart");
writeFileSync(join(dataOut, "privacy.md"), policy[1].replace(/\\\$/g, "$").replace(/\\'/g, "'").trim() + "\n");

console.log(
  `sync-content: ${designs.length} templates, ${releases.length} releases, privacy policy, screenshots and widgets`,
);
