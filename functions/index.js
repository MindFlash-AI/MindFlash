// 1. Import the Firebase Functions HTTP trigger
const { onRequest } = require("firebase-functions/v2/https");
const express = require('express');
const cors = require('cors');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const app = express();
// 2. Firebase requires cors to explicitly allow origins
app.use(cors({ origin: true })); 
app.use(express.json({ limit: '50mb' }));

// 3. Initialize Gemini.
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// 4. The Generation Route
app.post('/generate-deck', async (req, res) => {
  try {
    const userPrompt = req.body.prompt || req.body.text || ""; 
    const { fileText, fileName, userContext } = req.body;
    
    // --- MIGRATION TO 3.1 FLASH-LITE PREVIEW ---
    const model = genAI.getGenerativeModel({ 
      model: 'gemini-3.1-flash-lite-preview', 
      generationConfig: { 
        responseMimeType: 'application/json',
      },
      systemInstruction: `You are MindFlash AI, a friendly and expert study assistant.\n${userContext || ""}\n\nRead the user's prompt carefully.\n- If they ask about their existing decks or progress, answer conversationally based on the context provided above.\n- If they are just chatting, ask a question, or need an explanation, respond conversationally.\n- If they ask you to ADD cards to an existing deck, generate the cards and select the action "edit_deck" using the correct targetDeckId.\n- If they explicitly ask you to generate a NEW flashcard deck AND provide a topic or document, you MUST generate a new deck using the "create_deck" action.\n\nCRITICAL RULES:\n1. NEVER invent random facts or random decks.\n2. If the user asks to create a deck but DOES NOT specify a topic and NO document is uploaded, DO NOT create a deck. Select action "chat" and conversationally ask them what topic they would like to study.\n3. ONLY use the provided document text if one is attached.\n\nALWAYS return your response exactly in this JSON format:\n{\n  "action": "chat" | "create_deck" | "edit_deck",\n  "reply": "Your conversational response here. Be encouraging.",\n  "deckName": "Short descriptive name (ONLY if action is create_deck)",\n  "subject": "General subject category (ONLY if action is create_deck)",\n  "targetDeckId": "The exact ID of the existing deck (ONLY if action is edit_deck)",\n  "cards": [\n    {"q": "Question", "a": "Answer"}\n  ] \n}`
    });

    let finalPrompt = "";

    if (userPrompt) {
      finalPrompt += `User Instructions: ${userPrompt}\n\n`;
    } else if (!userPrompt && !fileText) {
      finalPrompt += `User Instructions: Say hello and ask what they want to study.\n\n`;
    }

    if (fileText) {
      finalPrompt += `Uploaded Document ('${fileName || "File"}'):\n---\n${fileText}\n---\n`;
      if (userPrompt) {
        finalPrompt += `\nPlease strictly use this document to fulfill the user's instructions above.`;
      } else {
        finalPrompt += `\nPlease extract the key concepts and generate a comprehensive flashcard deck from this document.`;
      }
    }

    const result = await model.generateContent(finalPrompt);
    let responseText = result.response.text();
    
    responseText = responseText.replace(/```json/g, '').replace(/```/g, '').trim();

    try {
      const jsonResponse = JSON.parse(responseText);
      res.status(200).json(jsonResponse);
    } catch (parseError) {
      console.error("JSON Parse Error. Gemini ignored instructions and outputted:", responseText);
      res.status(200).json({
        action: "chat",
        reply: responseText 
      });
    }

  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ error: 'Failed to generate content' });
  }
});

exports.api = onRequest(app);