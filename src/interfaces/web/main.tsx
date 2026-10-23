import React from "react";
import { createRoot } from "react-dom/client";

function App() {
  return (
    <main>
      <h1>Nemeo</h1>
      <p>Your budget, on pace.</p>
    </main>
  );
}

const root = document.getElementById("root");
if (!root) {
  throw new Error("Web root element is missing");
}

createRoot(root).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
