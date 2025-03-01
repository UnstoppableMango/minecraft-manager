export interface Version {
  semver: string;
  date: Date;
  href: string;
}

export interface McVersionsNet {
  stable: Version[];
  snapshot: Version[];
  beta: Version[];
  alpha: Version[];
}

export const emptyMcVersionsNet: McVersionsNet = {
  alpha: [],
  beta: [],
  snapshot: [],
  stable: [],
};

export function getMajor(v: Version): string | undefined {
  return v.semver.split('.')[0];
}

export function getMinor(v: Version): string | undefined {
  return v.semver.split('.')[1];
}

export function getPatch(v: Version): string | undefined {
  return v.semver.split('.')[2];
}

function fetchMcVersions(): Promise<string> {
  console.warn('fetching https://mcversions.net');
  return fetch('https://mcversions.net').then(x => x.text())
}

function resolveHref(href: string): Promise<string> {
  console.warn(`fetching https://mcversions.net/${href}`);
  return fetch(`https://mcversions.net/${href}`).then(x => x.text());
}

async function getOrCache(key: string, fn: () => Promise<string>): Promise<string> {
  let value = localStorage.getItem(key)
  if (!value) {
    value = await fn();
    localStorage.setItem(key, value);
  }

  return value;
}

function parseVersion(elem: Element): Version {
  const time = elem.querySelector('time');
  const download = elem.querySelector('a');
  
  return {
    date: time ? new Date(time.dateTime) : new Date(),
    href: download?.href ?? '',
    semver: elem.id,
  };
}

function parseVersions(elem: Element): Version[] {
  if (!elem.classList.contains('items')) {
    console.warn('expected element to have the "items" class, version parsing may fail');
  }

  return Array.from(elem.children).map(parseVersion);
}

function toVersions(rawhtml: string): McVersionsNet {
  const html = new DOMParser().parseFromString(rawhtml, 'text/html');

  const elems = html.querySelectorAll('h5').values()
    .reduce<Record<keyof McVersionsNet, Element | null>>((acc, value) => {
      const list = value.nextElementSibling;
      const name = value.textContent;

      if (!list || !name) return acc;

      switch (true) {
        case /stable releases/i.test(name):
          return { ...acc, stable: list };
        case /snapshot preview/i.test(name):
          return { ...acc, snapshot: list };
        case /beta/i.test(name):
          return { ...acc, beta: list };
        case /alpha/i.test(name):
          return { ...acc, alpha: list };
        default:
          return acc;
      }
    }, { alpha: null, beta: null, snapshot: null, stable: null });

  return {
    alpha: elems.alpha ? parseVersions(elems.alpha) : [],
    beta: elems.beta ? parseVersions(elems.beta) : [],
    snapshot: elems.snapshot ? parseVersions(elems.snapshot) : [],
    stable: elems.stable ? parseVersions(elems.stable) : []
  };
}

export function listVersions(): Promise<McVersionsNet> {
  return getOrCache('mcversions.net', fetchMcVersions)
    .then(toVersions);
}

export function getDownloadUrl(v: Version): Promise<string> {
  return getOrCache(v.href, () => resolveHref(v.href));
}
