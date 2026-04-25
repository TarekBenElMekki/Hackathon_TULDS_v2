"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { teams } from "@/lib/dashboard-data";

export default function AdminPage() {
  const router = useRouter();
  const [selectedTeam, setSelectedTeam] = useState("RB");
  const [pointsToAdd, setPointsToAdd] = useState(10);
  const [messageInput, setMessageInput] = useState("");
  const [showPreview, setShowPreview] = useState(false);

  const sendToDashboard = (action: string, data: any) => {
    localStorage.setItem("f1_admin_action", JSON.stringify({
      action,
      data,
      timestamp: Date.now()
    }));
    setShowPreview(true);
    setTimeout(() => setShowPreview(false), 2000);
  };

  const pushMessage = () => {
    const message = messageInput || "Amazing overtake in Sector 2!";
    sendToDashboard("message", { title: "RACE CONTROL", message });
    setMessageInput("");
  };

  const showGif = () => {
    const gifs = [
      "https://media.giphy.com/media/3o7abB06u9bNzA8LC8/giphy.gif",
      "https://media.giphy.com/media/l0MYEqEzwMWFCg8Ji/giphy.gif",
      "https://media.giphy.com/media/xT9IgzoKnw3m7r7QAQ/giphy.gif"
    ];
    const randomGif = gifs[Math.floor(Math.random() * gifs.length)];
    sendToDashboard("gif", { url: randomGif });
  };

  const triggerSafetyCar = () => {
    sendToDashboard("safety_car", { active: true });
  };

  const triggerFastestLap = () => {
    sendToDashboard("fastest_lap", { team: selectedTeam });
  };

  const updatePoints = () => {
    sendToDashboard("points", { team: selectedTeam, points: pointsToAdd });
  };

  return (
    <div style={{
      minHeight: "100vh",
      background: "linear-gradient(135deg, #0A0A0E 0%, #15151E 100%)",
      padding: "20px",
      fontFamily: "'Titillium Web', sans-serif"
    }}>
      {showPreview && (
        <div style={{
          position: "fixed",
          top: "20px",
          right: "20px",
          background: "linear-gradient(135deg, #E10600, #8B0000)",
          padding: "15px 25px",
          borderRadius: "8px",
          color: "white",
          zIndex: 1000
        }}>
<<<<<<< HEAD
          ÃƒÂ¢Ã…â€œÃ¢â‚¬Å“ Command sent to dashboard!
=======
          âœ“ Command sent to dashboard!
>>>>>>> b40135fb7f8bc52b4cde0691937b34a19f8ce3ba
        </div>
      )}

      <div style={{ maxWidth: "1200px", margin: "0 auto" }}>
        <div style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: "30px",
          padding: "20px",
          background: "rgba(225,6,0,0.1)",
          borderBottom: "3px solid #E10600",
          borderRadius: "8px"
        }}>
          <div>
<<<<<<< HEAD
            <h1 style={{ color: "#E10600", fontSize: "28px", margin: 0 }}>ÃƒÂ°Ã…Â¸Ã…Â½Ã‚Â® RACE CONTROL</h1>
=======
            <h1 style={{ color: "#E10600", fontSize: "28px", margin: 0 }}>ðŸŽ® RACE CONTROL</h1>
>>>>>>> b40135fb7f8bc52b4cde0691937b34a19f8ce3ba
            <p style={{ color: "#C0C0C0", margin: "5px 0 0" }}>Admin Dashboard | Live Race Management</p>
          </div>
          <button
            onClick={() => router.push("/")}
            style={{
              background: "rgba(255,255,255,0.1)",
              border: "1px solid #E10600",
              color: "white",
              padding: "10px 20px",
              borderRadius: "5px",
              cursor: "pointer",
              fontWeight: "bold"
            }}
          >
<<<<<<< HEAD
            ÃƒÂ¢Ã¢â‚¬Â Ã‚Â BACK TO DASHBOARD
=======
            â† BACK TO DASHBOARD
>>>>>>> b40135fb7f8bc52b4cde0691937b34a19f8ce3ba
          </button>
        </div>

        <div style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(300px, 1fr))",
          gap: "20px"
        }}>
          {/* Message Control */}
          <div style={{
            background: "rgba(30,30,40,0.95)",
            border: "1px solid rgba(225,6,0,0.3)",
            borderRadius: "8px",
            padding: "20px"
          }}>
<<<<<<< HEAD
            <h3 style={{ color: "#E10600", marginBottom: "15px" }}>ÃƒÂ°Ã…Â¸Ã¢â‚¬â„¢Ã‚Â¬ MESSAGE CONTROL</h3>
=======
            <h3 style={{ color: "#E10600", marginBottom: "15px" }}>ðŸ’¬ MESSAGE CONTROL</h3>
>>>>>>> b40135fb7f8bc52b4cde0691937b34a19f8ce3ba
            <input
              type="text"
              value={messageInput}
              onChange={(e) => setMessageInput(e.target.value)}
              placeholder="Enter race message..."
              style={{
                width: "100%",
                padding: "10px",
                marginBottom: "10px",
                background: "#1E1E28",
                border: "1px solid #38383F",
                color: "white",
                borderRadius: "5px"
              }}
            />
            <button
              onClick={pushMessage}
              style={{
                width: "100%",
                background: "linear-gradient(135deg, #E10600, #8B0000)",
                border: "none",
                color: "white",
                padding: "12px",
                borderRadius: "5px",
                cursor: "pointer",
                fontWeight: "bold"
              }}
            >
<<<<<<< HEAD
              ÃƒÂ°Ã…Â¸Ã¢â‚¬Å“Ã‚Â¢ PUSH TO DASHBOARD
=======
              ðŸ“¢ PUSH TO DASHBOARD
>>>>>>> b40135fb7f8bc52b4cde0691937b34a19f8ce3ba
            </button>
          </div>

          {/* GIF Control */}
          <div style={{
            background: "rgba(30,30,40,0.95)",
            border: "1px solid rgba(225,6,0,0.3)",
            borderRadius: "8px",
            padding: "20px"
          }}>
<<<<<<< HEAD
            <h3 style={{ color: "#E10600", marginBottom: "15px" }}>ÃƒÂ°Ã…Â¸Ã…Â½Ã‚Â¥ VISUAL EFFECTS</h3>
=======
            <h3 style={{ color: "#E10600", marginBottom: "15px" }}>ðŸŽ¥ VISUAL EFFECTS</h3>
>>>>>>> b40135fb7f8bc52b4cde0691937b34a19f8ce3ba
            <button
              onClick={showGif}
              style={{
                width: "100%",
                background: "linear-gradient(135deg, #E10600, #8B0000)",
                border: "none",
                color: "white",
                padding: "12px",
                borderRadius: "5px",
                cursor: "pointer",
                fontWeight: "bold"
              }}
            >
<<<<<<< HEAD
              ÃƒÂ°Ã…Â¸Ã…Â½Ã‚Â¬ SHOW RANDOM GIF
=======
              ðŸŽ¬ SHOW RANDOM GIF
>>>>>>> b40135fb7f8bc52b4cde0691937b34a19f8ce3ba
            </button>
          </div>

          {/* Points Control */}
          <div style={{
            background: "rgba(30,30,40,0.95)",
            border: "1px solid rgba(225,6,0,0.3)",
            borderRadius: "8px",
            padding: "20px"
          }}>
<<<<<<< HEAD
            <h3 style={{ color: "#E10600", marginBottom: "15px" }}>ÃƒÂ°Ã…Â¸Ã¢â‚¬Å“Ã…Â  POINTS CONTROL</h3>
=======
            <h3 style={{ color: "#E10600", marginBottom: "15px" }}>ðŸ“Š POINTS CONTROL</h3>
>>>>>>> b40135fb7f8bc52b4cde0691937b34a19f8ce3ba
            <select
              value={selectedTeam}
              onChange={(e) => setSelectedTeam(e.target.value)}
              style={{
                width: "100%",
                padding: "10px",
                marginBottom: "10px",
                background: "#1E1E28",
                border: "1px solid #38383F",
                color: "white",
                borderRadius: "5px"
              }}
            >
              {teams.map(team => (
                <option key={team.code} value={team.code}>{team.name} ({team.code})</option>
              ))}
            </select>
            <input
              type="number"
              value={pointsToAdd}
              onChange={(e) => setPointsToAdd(Number(e.target.value))}
              style={{
                width: "100%",
                padding: "10px",
                marginBottom: "10px",
                background: "#1E1E28",
                border: "1px solid #38383F",
                color: "white",
                borderRadius: "5px"
              }}
            />
            <button
              onClick={updatePoints}
              style={{
                width: "100%",
                background: "linear-gradient(135deg, #E10600, #8B0000)",
                border: "none",
                color: "white",
                padding: "12px",
                borderRadius: "5px",
                cursor: "pointer",
                fontWeight: "bold"
              }}
            >
<<<<<<< HEAD
              ÃƒÂ¢Ã…Â¾Ã¢â‚¬Â¢ ADD POINTS
=======
              âž• ADD POINTS
>>>>>>> b40135fb7f8bc52b4cde0691937b34a19f8ce3ba
            </button>
          </div>

          {/* Race Events */}
          <div style={{
            background: "rgba(30,30,40,0.95)",
            border: "1px solid rgba(225,6,0,0.3)",
            borderRadius: "8px",
            padding: "20px"
          }}>
<<<<<<< HEAD
            <h3 style={{ color: "#E10600", marginBottom: "15px" }}>ÃƒÂ°Ã…Â¸Ã‚ÂÃ‚Â RACE EVENTS</h3>
=======
            <h3 style={{ color: "#E10600", marginBottom: "15px" }}>ðŸ RACE EVENTS</h3>
>>>>>>> b40135fb7f8bc52b4cde0691937b34a19f8ce3ba
            <button
              onClick={triggerSafetyCar}
              style={{
                width: "100%",
                background: "#FFD700",
                color: "#000",
                padding: "12px",
                borderRadius: "5px",
                cursor: "pointer",
                fontWeight: "bold",
                border: "none",
                marginBottom: "10px"
              }}
            >
<<<<<<< HEAD
              ÃƒÂ°Ã…Â¸Ã…Â¡Ã‚Â¨ DEPLOY SAFETY CAR
=======
              ðŸš¨ DEPLOY SAFETY CAR
>>>>>>> b40135fb7f8bc52b4cde0691937b34a19f8ce3ba
            </button>
            <button
              onClick={triggerFastestLap}
              style={{
                width: "100%",
                background: "#00D26A",
                color: "#000",
                padding: "12px",
                borderRadius: "5px",
                cursor: "pointer",
                fontWeight: "bold",
                border: "none"
              }}
            >
<<<<<<< HEAD
              ÃƒÂ¢Ã…Â¡Ã‚Â¡ FASTEST LAP
=======
              âš¡ FASTEST LAP
>>>>>>> b40135fb7f8bc52b4cde0691937b34a19f8ce3ba
            </button>
          </div>
        </div>

        <div style={{
          marginTop: "30px",
          padding: "20px",
          background: "rgba(0,0,0,0.5)",
          borderRadius: "8px",
          border: "1px solid rgba(225,6,0,0.2)"
        }}>
<<<<<<< HEAD
          <h4 style={{ color: "#E10600", marginBottom: "10px" }}>ÃƒÂ°Ã…Â¸Ã¢â‚¬Å“Ã¢â‚¬Â¹ INSTRUCTIONS</h4>
          <ul style={{ color: "#C0C0C0", fontSize: "12px", lineHeight: "1.8" }}>
            <li>ÃƒÂ°Ã…Â¸Ã…Â½Ã‚Â® All controls send real-time commands to the main dashboard</li>
            <li>ÃƒÂ°Ã…Â¸Ã¢â‚¬â„¢Ã‚Â¬ Messages appear as overlays on the main screen</li>
            <li>ÃƒÂ°Ã…Â¸Ã…Â½Ã‚Â¥ GIFs create dramatic visual effects during key moments</li>
            <li>ÃƒÂ°Ã…Â¸Ã¢â‚¬Å“Ã…Â  Points can be awarded to specific teams in real-time</li>
            <li>ÃƒÂ°Ã…Â¸Ã‚ÂÃ‚Â Safety Car and Fastest Lap triggers create race events</li>
=======
          <h4 style={{ color: "#E10600", marginBottom: "10px" }}>ðŸ“‹ INSTRUCTIONS</h4>
          <ul style={{ color: "#C0C0C0", fontSize: "12px", lineHeight: "1.8" }}>
            <li>ðŸŽ® All controls send real-time commands to the main dashboard</li>
            <li>ðŸ’¬ Messages appear as overlays on the main screen</li>
            <li>ðŸŽ¥ GIFs create dramatic visual effects during key moments</li>
            <li>ðŸ“Š Points can be awarded to specific teams in real-time</li>
            <li>ðŸ Safety Car and Fastest Lap triggers create race events</li>
>>>>>>> b40135fb7f8bc52b4cde0691937b34a19f8ce3ba
          </ul>
        </div>
      </div>
    </div>
  );
}
<<<<<<< HEAD

=======
>>>>>>> b40135fb7f8bc52b4cde0691937b34a19f8ce3ba
