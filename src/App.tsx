import { useEffect, useState } from 'react'
import reactLogo from './assets/react.svg'
import viteLogo from '/vite.svg'
import './App.css'
import { createVersionsClient } from './versions';
import { Version } from './dev/unmango/v1alpha1/versions_pb';

const client = createVersionsClient();

function App() {
  const [count, setCount] = useState(0);
	const [versions, setVersions] = useState<Version[]>([]);

	useEffect(() => {
		client.list({}).then((x) => setVersions(x.versions)).catch((e) => console.error(e));
	}, []);

  return (
    <>
      <div>
        <a href="https://vite.dev">
          <img src={viteLogo} className="logo" alt="Vite logo" />
        </a>
        <a href="https://react.dev">
          <img src={reactLogo} className="logo react" alt="React logo" />
        </a>
      </div>
      <h1>Vite + React</h1>
			<h2>{versions.map(x => x.version)}</h2>
      <div className="card">
        <button type="button" onClick={() => setCount((count) => count + 1)}>
          count is {count}
        </button>
        <p>
          Edit <code>src/App.tsx</code> and save to test HMR
        </p>
      </div>
      <p className="read-the-docs">
        Click on the Vite and React logos to learn more
      </p>
    </>
  )
}

export default App
