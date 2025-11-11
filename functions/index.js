const functions = require("firebase-functions");
const {setGlobalOptions} = require("firebase-functions/v2");
const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

setGlobalOptions({maxInstances: 10});

exports.chatProxy = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  const userPrompt = req.body && req.body.prompt;
  if (!userPrompt) {
    res.status(400).json({error: "Missing prompt"});
    return;
  }

  try {
    const apiKey = functions.config().ai.key;
    if (!apiKey) {
      logger.error("AI key missing from functions config");
      res.status(500).json({error: "Server misconfiguration"});
      return;
    }

    const aiResponse = await fetch("https://api.provider.com/v1/chat", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-3.5",
        messages: userPrompt,
      }),
    });

    if (!aiResponse.ok) {
      const errorText = await aiResponse.text();
      logger.error("AI provider request failed", {
        status: aiResponse.status,
        errorText,
      });
      res.status(502).json({error: "AI provider error"});
      return;
    }

    const data = await aiResponse.json();
    res.json(data);
  } catch (error) {
    logger.error("chatProxy failed", error);
    res.status(500).json({error: "Internal server error"});
  }
});
