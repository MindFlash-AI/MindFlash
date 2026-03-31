const { onRequest } = require("firebase-functions/v2/https");
const express = require('express');
const cors = require('cors');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp();
const db = admin.firestore();

const app = express();
app.use(cors({ origin: true })); 
app.use(express.json({ limit: '50mb' }));

// 1. App Check Middleware
const requireAppCheck = async (req, res, next) => {
    const appCheckToken = req.header('X-Firebase-AppCheck');
    if (!appCheckToken) return res.status(401).json({ error: 'Unauthorized', details: 'App Check token missing.' });
    try {
        await admin.appCheck().verifyToken(appCheckToken);
        return next();
    } catch (err) {
        return res.status(401).json({ error: 'Unauthorized', details: 'Invalid App Check token.' });
    }
};

// 2. Auth Middleware
const requireAuth = async (req, res, next) => {
    const authHeader = req.header('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Unauthorized', details: 'Missing auth token.' });
    }
    const idToken = authHeader.split('Bearer ')[1];
    try {
        req.user = await admin.auth().verifyIdToken(idToken);
        return next();
    } catch (err) {
        return res.status(401).json({ error: 'Unauthorized', details: 'Invalid auth token.' });
    }
};

// 3. The Secured Route
app.post('/generate-deck', requireAppCheck, requireAuth, async (req, res) => {
  try {
    const uid = req.user.uid;
    const energyRef = db.collection('users').doc(uid).collection('stats').doc('energy');

    // --- SERVER SIDE ECONOMY ENFORCEMENT (SELF-HEALING) ---
    await db.runTransaction(async (transaction) => {
        const energyDoc = await transaction.get(energyRef);
        
        if (!energyDoc.exists) {
            // Self-Healing: The backend creates the wallet for the user and deducts 1
            transaction.set(energyRef, {
                energy: 9, // 10 Max - 1 for this request
                lastResetDate: admin.firestore.FieldValue.serverTimestamp(),
                serverPing: admin.firestore.FieldValue.serverTimestamp()
            });
        } else {
            const currentEnergy = energyDoc.data().energy || 0;
            if (currentEnergy <= 0) {
                throw new Error("INSUFFICIENT_ENERGY");
            }
            // Securely deduct 1
            transaction.update(energyRef, { energy: currentEnergy - 1 });
        }
    });

    // --- PROCEED TO GEMINI ---
    if (!process.env.GEMINI_API_KEY) {
      return res.status(500).json({ error: 'Server configuration error: Missing API Key.' });
    }

    const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
    const userPrompt = req.body.prompt || req.body.text || ""; 
    const { fileText, fileName, userContext } = req.body;
    
    const model = genAI.getGenerativeModel({ 
      model: 'gemini-3.1-flash-lite-preview', 
      generationConfig: { responseMimeType: 'application/json' },
      systemInstruction: `You are MindFlash AI, a friendly and expert study assistant.\n${userContext || ""}\n\nRead the user's prompt carefully.\n- If they ask about their existing decks or progress, answer conversationally based on the context provided above.\n- If they are just chatting, ask a question, or need an explanation, respond conversationally.\n- If they ask you to ADD cards to an existing deck, generate the cards and select the action "edit_deck" using the correct targetDeckId.\n- If they explicitly ask you to generate a NEW flashcard deck AND provide a topic or document, you MUST generate a new deck using the "create_deck" action.\n\nCRITICAL RULES:\n1. NEVER invent random facts or random decks.\n2. If the user asks to create a deck but DOES NOT specify a topic and NO document is uploaded, DO NOT create a deck. Select action "chat" and conversationally ask them what topic they would like to study.\n3. ONLY use the provided document text if one is attached.\n\nALWAYS return your response exactly in this JSON format:\n{\n  "action": "chat" | "create_deck" | "edit_deck",\n  "reply": "Your conversational response here. Be encouraging.",\n  "deckName": "Short descriptive name (ONLY if action is create_deck)",\n  "subject": "General subject category (ONLY if action is create_deck)",\n  "targetDeckId": "The exact ID of the existing deck (ONLY if action is edit_deck)",\n  "cards": [\n    {"q": "Question", "a": "Answer"}\n  ] \n}`
    });

    let finalPrompt = "";
    if (userPrompt) finalPrompt += `User Instructions: ${userPrompt}\n\n`;
    else if (!userPrompt && !fileText) finalPrompt += `User Instructions: Say hello and ask what they want to study.\n\n`;

    if (fileText) {
      finalPrompt += `Uploaded Document ('${fileName || "File"}'):\n---\n${fileText}\n---\n`;
      if (userPrompt) finalPrompt += `\nPlease strictly use this document to fulfill the user's instructions above.`;
      else finalPrompt += `\nPlease extract the key concepts and generate a comprehensive flashcard deck from this document.`;
    }

    const result = await model.generateContent(finalPrompt);
    let responseText = result.response.text();
    responseText = responseText.replace(/```json/g, '').replace(/```/g, '').trim();

    try {
      res.status(200).json(JSON.parse(responseText));
    } catch (parseError) {
      res.status(200).json({ action: "chat", reply: responseText });
    }

  } catch (error) {
    if (error.message === "INSUFFICIENT_ENERGY") {
        return res.status(403).json({ error: "Out of energy. Please watch an ad to recharge." });
    }
    console.error("Detailed Error:", error.message || error);
    res.status(500).json({ error: 'Failed to generate content', details: error.message });
  }
});

exports.api = onRequest({ timeoutSeconds: 300, memory: "512MiB" }, app);