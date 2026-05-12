import {copyFile, mkdir} from 'node:fs/promises';
import {dirname, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

const engineRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const appRoot = resolve(engineRoot, '..');

const assets = [
  ['assets/images/ikigabo.png', 'public/app/logo.png'],
  ['docs/assets/images/public/dashabord_light.jpg', 'public/app/dashboard-light.jpg'],
  ['docs/assets/images/public/stats_light.jpg', 'public/app/stats-light.jpg'],
  ['docs/assets/images/public/settings_light.jpg', 'public/app/settings-light.jpg'],
  [
    'docs/assets/images/public/new_transaction_page_light.jpg',
    'public/app/new-transaction-light.jpg'
  ],
  [
    'docs/assets/images/public/transactions_list_light.jpg',
    'public/app/transactions-list-light.jpg'
  ],
  ['docs/assets/images/public/on_boarding_dark1.jpg', 'public/app/onboarding-dark-1.jpg'],
  ['docs/assets/images/public/on_boarding_dark2.jpg', 'public/app/onboarding-dark-2.jpg'],
  ['docs/assets/images/public/on_boarding_dark3.jpg', 'public/app/onboarding-dark-3.jpg'],
  ['docs/assets/images/public/pin_page_dark.jpg', 'public/app/pin-dark.jpg'],
  ['docs/assets/images/public/dahsbaorad_dark.jpg', 'public/app/dashboard-dark.jpg'],
  ['docs/assets/images/public/stats_page_dark.jpg', 'public/app/stats-dark.jpg']
];

await Promise.all(
  assets.map(async ([from, to]) => {
    const source = resolve(appRoot, from);
    const destination = resolve(engineRoot, to);
    await mkdir(dirname(destination), {recursive: true});
    await copyFile(source, destination);
  })
);

console.log(`Synced ${assets.length} app assets into PromoVideoEngine/public/app`);
