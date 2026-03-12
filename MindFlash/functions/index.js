// 1. Import the Firebase Functions HTTP trigger
const { onRequest } = require("firebase-functions/v2/https");
const express = require('express');
const cors = require('cors');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const app = express();
// 2. Firebase requires cors to explicitly allow origins
app.use(cors({ origin: true })); 
app.use(express.json({ limit: '50mb' }));

// 3. Initialize Gemini. Firebase automatically loads the .env file in the functions folder!
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// 4. Change the route to '/generate-deck' (Firebase handles the base URL)
app.post('/generate-deck', async (req, res) => {
  try {
    const { prompt, fileText, fileName, userContext } = req.body;
    
    const model = genAI.getGenerativeModel({ 
      model: 'gemini-2.5-flash',
      generationConfig: { responseMimeType: 'application/json' },
      systemInstruction: `You are MindFlash AI, a friendly and expert study assistant.\n${userContext}\n\nRead the user's prompt carefully.\n- If they ask about their existing decks or progress, answer conversationally based on the context provided above.\n- If they are just chatting, ask a question, or need an explanation, respond conversationally.\n- If they ask you to ADD cards to an existing deck, generate the cards and select the action "edit_deck" using the correct targetDeckId.\n- If they explicitly ask you to generate, create, or make a NEW flashcard deck, OR if they upload a document (and don't specify an existing deck), you MUST generate a new deck using the "create_deck" action.\n\nALWAYS return your response exactly in this JSON format:\n{\n  "action": "chat" | "create_deck" | "edit_deck",\n  "reply": "Your conversational response here. Be encouraging.",\n  "deckName": "Short descriptive name (ONLY if action is create_deck)",\n  "subject": "General subject category (ONLY if action is create_deck)",\n  "targetDeckId": "The exact ID of the existing deck (ONLY if action is edit_deck)",\n  "cards": [\n    {"q": "Question", "a": "Answer"}\n  ] // (ONLY if action is create_deck OR edit_deck)\n}`
    });

    let finalPrompt = prompt || "";
    if (fileText) {
      finalPrompt = `I have uploaded a document named '${fileName}'. Here is the content:\n\n---\n${fileText}\n---\n\nPlease extract the key concepts...`;
    }

    const result = await model.generateContent(finalPrompt);
    let responseText = result.response.text();
    responseText = responseText.replace(/```json/g, '').replace(/```/g, '').trim();

    // Send the JSON back to your Flutter app
    res.json(JSON.parse(responseText));

  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ error: 'Failed to generate content' });
  }
});

// 5. THIS IS THE MOST IMPORTANT CHANGE: Export the app as a Firebase Function!
exports.api = onRequest(app);