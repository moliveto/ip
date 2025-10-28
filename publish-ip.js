// publish-ip.js
const GH_API = "https://api.github.com";
const FILE_PATH = "ip.json";

async function getJson(url) {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), 5000);
  try {
    const r = await fetch(url, { signal: ctrl.signal });
    if (!r.ok) throw new Error(`HTTP ${r.status}`);
    return await r.json();
  } finally {
    clearTimeout(t);
  }
}

async function detectIps() {
  const [v4, v6] = await Promise.allSettled([
    getJson("https://api.ipify.org?format=json"),
    getJson("https://api64.ipify.org?format=json")
  ]);
  return {
    ipv4: v4.status === "fulfilled" ? v4.value.ip : null,
    ipv6: v6.status === "fulfilled" ? v6.value.ip : null
  };
}

function envOrThrow(name) {
  const v = process.env[name];
  if (!v) throw new Error(`Falta ${name}`);
  return v;
}

async function getExistingSha(owner, repo, path, branch, token) {
  const url = `${GH_API}/repos/${owner}/${repo}/contents/${encodeURIComponent(path)}?ref=${encodeURIComponent(branch)}`;
  const r = await fetch(url, {
    headers: { Authorization: `Bearer ${token}`, "User-Agent": "publish-my-ip-script" }
  });
  if (r.status === 404) return null;
  if (!r.ok) throw new Error(`GET contents failed: ${r.status}`);
  const j = await r.json();
  return j.sha ?? null;
}

async function putFile(owner, repo, path, branch, token, content, sha) {
  const url = `${GH_API}/repos/${owner}/${repo}/contents/${encodeURIComponent(path)}`;
  const body = {
    message: `chore(ip): update ${path}`,
    content: Buffer.from(content).toString("base64"),
    branch,
    ...(sha ? { sha } : {})
  };
  const r = await fetch(url, {
    method: "PUT",
    headers: {
      Authorization: `Bearer ${token}`,
      "User-Agent": "publish-my-ip-script",
      "Content-Type": "application/json"
    },
    body: JSON.stringify(body)
  });
  if (!r.ok) {
    const txt = await r.text().catch(() => "");
    throw new Error(`PUT contents failed: ${r.status} ${txt}`);
  }
  return r.json();
}

(async function main() {
  try {
    const owner  = envOrThrow("GITHUB_OWNER");
    const repo   = envOrThrow("GITHUB_REPO");
    const branch = envOrThrow("GITHUB_BRANCH");
    const token  = envOrThrow("GITHUB_TOKEN");

    const { ipv4, ipv6 } = await detectIps();
    if (!ipv4 && !ipv6) throw new Error("No se pudo detectar ninguna IP pública");

    const payload = {
      ipv4,
      ipv6,
      timestampUtc: new Date().toISOString()
    };

    const sha = await getExistingSha(owner, repo, FILE_PATH, branch, token);
    await putFile(owner, repo, FILE_PATH, branch, token, JSON.stringify(payload, null, 2), sha);

    console.log("OK:", payload);
  } catch (err) {
    console.error("ERROR:", err.message);
    process.exitCode = 1;
  }
})();
