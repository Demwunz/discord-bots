# Visual Reference

Screenshots and visual examples of the Raffle Bot interface.

---

## Raffle Embed

```
+------------------------------------------+
| 🎟️ Raffle Time! — Amazing Item            |
+------------------------------------------+
| [Image if photos added]                  |
|                                          |
| A beautiful CGC 9.8 graded comic...      |
|                                          |
| 🔗 Grading: View Certificate (if link)   |
|                                          |
| 💵 Spots are $10 each — grab as many     |
|    as you want!                          |
| 🎯 25 total spots — pick your spot by    |
|    clicking the buttons below!           |
|                                          |
| Raffles will run as soon as all spots    |
| are filled.                              |
| If we don't fill it up within 7 days,    |
| this one will close.                     |
|                                          |
| 📦 Shipping Info:                        |
| 🇺🇸 US: Free USPS Ground Advantage        |
| 🌍 No international shipping             |
|                                          |
| 💳 Payment collected once all spots are  |
|    full — click My Spots to pay.         |
+------------------------------------------+
```

**Note:** Payment details (Venmo/PayPal/Zelle info) are shown only when you click "Pay for Your Spots" — not in the main embed.

---

## Spot Button Grid

### Before Raffle is Full (No Payment Emojis)

```
[1. Claim] [2. Claim] [3. @Kim] [4. Claim] [5. Claim]
[6. @Joe] [7. Claim] [8. Claim] [9. @Amy] [10.Claim]
...
[🎟️ My Spots]
```

### After Raffle is Full (Payment Phase)

```
[1. @Kim 💵] [2. @Bob 💵] [3. @Kim 💵] [4. @Sue 💸] [5. @Tom 💵]
[6. @Joe 💵] [7. @Meg 💵] [8. @Dan 💵] [9. @Amy 💸] [10.@Pat ✅]
...
[🎟️ My Spots]
```

### Button States Legend

```
[#. Claim]    = Available (blue)
[#. @Name]    = Claimed, raffle not full (gray)
[#. @Name 💵] = Payment pending, raffle full (gray)
[#. @Name 💸] = User marked paid (gray)
[#. @Name ✅] = Admin confirmed paid (green)
```

---

## Large Raffles (>20 spots)

For raffles with more than 20 spots:
- First message shows spots 1-20 plus the My Spots button
- Reply messages show spots 21-40, 41-60, etc.

---

## Control Panel View

```
+------------------------------------------+
| 🎰 Raffle Control Panel                   |
+------------------------------------------+
| Welcome to the Raffle Bot control panel. |
| Use the buttons below to manage raffles. |
|                                          |
| Quick Actions:                           |
| - Click Create New Raffle to start       |
| - Click List Active Raffles to see all   |
|                                          |
| Active Raffles: 3                        |
+------------------------------------------+
| [🎟️ Create New Raffle] [📋 List Active]  |
+------------------------------------------+
```

---

## Admin Thread View

```
+----------------------------------+
|  Raffle: Amazing Item            |
+----------------------------------+
|  Status: Active                  |
|  Price: $10 per spot             |
|  Total Spots: 25                 |
|  Claimed: 15/25                  |
|  Paid: 8                         |
|  Pending Payment: 7              |
+----------------------------------+
| [📸 Add Photos]                  |
| [💰 Mark Paid] [⏰ Extend]        |
| [🔒 Close Raffle]                |
+----------------------------------+
```

---

## Admin Payment Notification

When a user marks their payment as sent:

```
💸 Spots #2, #3, #4 claimed by @user marked paid
Venmo: `@username` • $30
[Confirmed] [Unconfirmed]
```

---

[← Back to Guide Index](../GUIDE.md)
