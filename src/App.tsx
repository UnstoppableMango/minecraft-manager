import "./index.css";
import { JSX, useEffect, useState } from 'react';
import { emptyMcVersionsNet, listVersions, McVersionsNet } from './versions';

export function App(): JSX.Element {
  const [loading, setLoading] = useState(true);
  const [versions, setVersions] = useState<McVersionsNet>(emptyMcVersionsNet);
  const [error, setError] = useState<string>();
  const [res, setRes] = useState<string>();

  useEffect(() => {
    if (loading && !versions.stable.length) {
      listVersions()
        .then(setVersions)
        .then(() => setLoading(false))
        .catch(setError)
    }
  }, []);

  useEffect(() => {
    if (!res) {
      fetch('/api/test').then(x => x.json()).then(x => setRes(x.message));
    }
  });

  if (error) {
    return (
      <span>Error: {error}</span>
    )
  }

  return (
    <div className="w-svw p-8 flex content-center">
      <div className="mx-auto w-1/2 h-1/3 p-2 rounded-md bg-green-700">
        <label htmlFor="versions" className='p-2'>Versions</label>
        <select name="versions" className='p-1 rounded-md bg-gray-800'>
          {versions.stable.map((v, i) => (
            <option key={i} value={v.semver} className='p-3'>
              {v.semver} {v.date.toLocaleDateString()}
            </option>
          ))}
        </select>
      </div>
      <div>
        <span>{res}</span>
      </div>
    </div>
  );
}

export default App;
