import "./index.css";
import { JSX, useEffect, useState } from 'react';
import { emptyMcVersionsNet, listVersions, McVersionsNet } from './versions';

export function App(): JSX.Element {
  const [loading, setLoading] = useState(true);
  const [versions, setVersions] = useState<McVersionsNet>(emptyMcVersionsNet);
  const [error, setError] = useState<string>();

  useEffect(() => {
    if (loading && !versions.stable.length) {
      listVersions()
        .then(setVersions)
        .then(() => setLoading(false))
        .catch(setError)
    }
  }, []);

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
          {versions.stable.map(v => (
            <option key={v.semver} value={v.semver} className='p-3'>
              <span>{v.semver} {v.date.toLocaleDateString()}</span>
            </option>
          ))}
        </select>
      </div>
    </div>
  );
}

export default App;
