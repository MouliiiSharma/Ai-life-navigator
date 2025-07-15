const axios = require('axios');
const secrets = require('./node-secrets');

const API_KEY = secrets.geminiApiKey; 

async function callGemini() {
  const url = `https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro:generateContent?key=${API_KEY}`;

  const requestBody = {
    contents: [
      {
        parts: [{ text: "Tell me a fun fact about the moon." }]
      }
    ]
  };

  try {
    const res = await axios.post(url, requestBody);
    console.log("✅ Gemini says:", res.data.candidates[0].content.parts[0].text);
  } catch (error) {
    console.error("❌ Error calling Gemini:", error.response?.data || error.message);
  }
}

callGemini();

