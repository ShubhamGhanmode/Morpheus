const { google } = require("googleapis");

let cachedAuth = null;

async function getAuthClient() {
  if (cachedAuth) return cachedAuth;
  const auth = new google.auth.GoogleAuth({
    scopes: ["https://www.googleapis.com/auth/cloud-platform"],
  });
  cachedAuth = await auth.getClient();
  return cachedAuth;
}

function normalizeEndpoint(value) {
  if (!value) return "";
  return value.endsWith("/") ? value : `${value}/`;
}

function resolveEndpoint(location, override) {
  const normalizedOverride = normalizeEndpoint(override);
  if (normalizedOverride) return normalizedOverride;
  if (!location) return "https://documentai.googleapis.com/";
  const trimmed = location.trim().toLowerCase();
  return `https://${trimmed}-documentai.googleapis.com/`;
}

function buildRequestBody({ content, mimeType, skipHumanReview }) {
  return {
    skipHumanReview: skipHumanReview !== false,
    rawDocument: {
      content,
      mimeType: mimeType || "image/jpeg",
    },
  };
}

async function processDocumentAi({
  content,
  mimeType,
  projectId,
  location,
  processorId,
  endpoint,
  skipHumanReview,
}) {
  if (!projectId || !location || !processorId) {
    throw new Error("Document AI config is missing.");
  }

  const authClient = await getAuthClient();
  const rootUrl = resolveEndpoint(location, endpoint);
  const documentai = google.documentai({
    version: "v1",
    auth: authClient,
    rootUrl,
  });
  const name = `projects/${projectId}/locations/${location}/processors/${processorId}`;
  const requestBody = buildRequestBody({
    content,
    mimeType,
    skipHumanReview,
  });

  const response = await documentai.projects.locations.processors.process({
    name,
    requestBody,
  });

  return response.data;
}

module.exports = {
  buildRequestBody,
  processDocumentAi,
  resolveEndpoint,
};
