import { Router } from "express";

const router = Router();

const inMemoryNotifications = [
  {
    id: "notif-1",
    type: "deadline",
    schemeId: "pm-kisan",
    title: {
      en: "PM-Kisan deadline coming up",
      ta: "பி.எம்-கிசான் கடைசி தேதி நெருங்குகிறது"
    },
    message: {
      en: "Submit your documents before the next installment date.",
      ta: "அடுத்த தவணைக்கு முன் உங்கள் ஆவணங்களை சமர்ப்பிக்கவும்."
    },
    triggerDate: "2025-01-15",
    read: false
  }
];

router.get("/", (req, res) => {
  res.json({ notifications: inMemoryNotifications });
});

router.post("/simulate", (req, res) => {
  const notification = {
    id: `notif-${Date.now()}`,
    ...req.body,
    read: false
  };
  inMemoryNotifications.push(notification);
  res.status(201).json({ notification });
});

router.post("/mark-read/:id", (req, res) => {
  const { id } = req.params;
  const notification = inMemoryNotifications.find((n) => n.id === id);
  if (!notification) {
    return res.status(404).json({ error: "Notification not found" });
  }
  notification.read = true;
  res.json({ notification });
});

export default router;
