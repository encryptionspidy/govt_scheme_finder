import { Router } from "express";

const router = Router();

const inMemoryNotifications = [
  {
    id: "notif-1",
    type: "deadline",
    schemeId: "national_scholarship_portal",
    title: {
      en: "National Scholarship deadline approaching",
      ta: "தேசிய கல்வி உதவித்தொகை கடைசி தேதி நெருங்குகிறது"
    },
    message: {
      en: "Complete your scholarship submission this week.",
      ta: "இந்த வாரத்தில் உங்கள் உதவித்தொகை விண்ணப்பத்தை முடிக்கவும்."
    },
    read: false,
    createdAt: new Date().toISOString()
  }
];

router.get("/", (_req, res) => {
  res.json({ data: inMemoryNotifications });
});

router.post("/simulate", (req, res) => {
  const notification = {
    id: `notif-${Date.now()}`,
    ...req.body,
    read: false,
    createdAt: new Date().toISOString()
  };
  inMemoryNotifications.unshift(notification);
  res.status(201).json({ data: notification });
});

router.post("/mark-read/:id", (req, res) => {
  const notification = inMemoryNotifications.find((item) => item.id === req.params.id);
  if (!notification) {
    return res.status(404).json({ error: "NotFound", message: "Notification not found" });
  }
  notification.read = true;
  return res.json({ data: notification });
});

export default router;
