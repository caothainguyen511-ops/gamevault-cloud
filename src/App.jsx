import React, { useMemo, useState } from "react";
import { Activity, ArrowDownRight, ArrowUpRight, Bell, Bluetooth, Check, ChevronRight, CircleHelp, Cloud, Command, Gamepad2, Gauge, Grid2X2, Headphones, Library, Monitor, MoreHorizontal, Play, Plus, Search, Settings2, ShieldCheck, SlidersHorizontal, Sparkles, Star, Wifi, X } from "lucide-react";

const games = [
  { name:"Cyberpunk 2077", studio:"CD PROJEKT RED", genre:"RPG · OPEN WORLD", art:"cyber", mark:"2077", time:"12.4 HRS", tag:"CONTINUE" },
  { name:"Apex Legends", studio:"RESPAWN", genre:"BATTLE ROYALE", art:"apex", mark:"APEX", time:"8.1 HRS", tag:"POPULAR" },
  { name:"Forza Horizon 5", studio:"PLAYGROUND GAMES", genre:"RACING · OPEN WORLD", art:"forza", mark:"FH5", time:"5.6 HRS", tag:"RACING" },
  { name:"The Witcher 3", studio:"CD PROJEKT RED", genre:"ACTION RPG", art:"witcher", mark:"WILD HUNT", time:"22.0 HRS", tag:"FAVORITE" }
];
function App(){
 const [tab,setTab]=useState("Overview"),[query,setQuery]=useState(""),[profile,setProfile]=useState("Balanced"),[showSettings,setShowSettings]=useState(false),[notice,setNotice]=useState("");
 const filtered=useMemo(()=>games.filter(g=>g.name.toLowerCase().includes(query.toLowerCase())),[query]);
 const nav=[["Overview",Grid2X2],["My Library",Library],["Controller",Gamepad2],["Performance",Gauge]];
 const toast=(s)=>{setNotice(s);setTimeout(()=>setNotice(""),2300)};
 return <div className="app-shell">
  <aside className="sidebar">
   <div className="brand"><div className="brand-icon"><Command size={21}/></div><div><b>GAMEVAULT</b><small>CLOUD PLATFORM</small></div></div>
   <div className="side-label">WORKSPACE</div>
   <nav>{nav.map(([n,I])=><button key={n} className={tab===n?"nav-item active":"nav-item"} onClick={()=>setTab(n)}><I size={18}/><span>{n}</span>{n==="My Library"&&<em>04</em>}</button>)}</nav>
   <div className="side-spacer"/>
   <div className="connection-card"><div className="connection-top"><span className="live-dot"/> SYSTEM READY</div><b>Cloud link idle</b><small>Connect a supported service to start a session.</small><div className="connection-line"><span/></div><button onClick={()=>toast("Cloud connection setup will be added with the streaming engine.")}>SET UP CONNECTION <ChevronRight size={13}/></button></div>
   <button className="profile" onClick={()=>toast("Profile settings are coming soon.")}><div className="avatar">GV</div><div><b>Player One</b><small>Local profile</small></div><MoreHorizontal size={19}/></button>
  </aside>
  <main className="main">
   <header className="topbar"><div className="crumb">GAMEVAULT <span>/</span> {tab.toUpperCase()}</div><div className="top-actions"><div className="status-pill"><span className="live-dot"/> ALL SYSTEMS NORMAL</div><button className="icon-btn" onClick={()=>toast("You're all caught up.")}><Bell size={18}/></button><button className="icon-btn" onClick={()=>setShowSettings(true)}><Settings2 size={18}/></button></div></header>
   {tab==="Overview"||tab==="My Library"? <div className="content">
    <section className="welcome"><div><div className="eyebrow"><Sparkles size={13}/> YOUR PERSONAL PLAY SPACE</div><h1>{tab==="Overview"?"Play without the wait.":"Your collection, in one place."}</h1><p>{tab==="Overview"?"One dashboard for your cloud sessions, favorite titles, and play setup.":"Pick up where you left off or explore your saved titles."}</p></div><div className="date-block"><span>YOUR VAULT</span><b>GAMING<br/>PROFILE <i>01</i></b></div></section>
    {tab==="Overview"&&<section className="hero-card"><div className="hero-noise"/><div className="hero-content"><div className="hero-kicker"><span className="tag">FEATURED SESSION</span><span className="mono">GV / 001</span></div><div className="hero-title">THE NIGHT<br/><i>IS YOURS.</i></div><p>Your next session starts here. Choose a title from your library and connect a cloud gaming service.</p><button className="primary-btn" onClick={()=>toast("Connect a cloud gaming service before starting a session.")}><Play size={15} fill="currentColor"/> START A SESSION</button></div><div className="hero-orbit"><div className="orbit o1"/><div className="orbit o2"/><div className="orbit-core"><Command size={54}/></div><span className="orbit-label">GV / CLOUD</span></div><div className="hero-index">01 <span>— 04</span></div></section>}
    <section className="stats-grid">
     <div className="stat-card"><div className="stat-head">LIBRARY SIZE <Library size={16}/></div><b>04 <small>TITLES</small></b><span className="stat-foot">Your saved collection</span></div>
     <div className="stat-card"><div className="stat-head">PLAY TIME <Activity size={16}/></div><b>48.1 <small>HRS</small></b><span className="stat-foot">Across sample activity</span></div>
     <div className="stat-card"><div className="stat-head">DEVICE STATUS <Monitor size={16}/></div><b className="stat-word">NOT LINKED</b><span className="stat-foot">Connect a device to continue</span></div>
    </section>
    <section className="library-section"><div className="section-head"><div><div className="eyebrow">CURATED FOR YOU</div><h2>{tab==="Overview"?"Recently in your vault":"All titles"}</h2></div><div className="library-tools"><div className="searchbox"><Search size={15}/><input value={query} onChange={e=>setQuery(e.target.value)} placeholder="Find a game..."/>{query&&<button onClick={()=>setQuery("")}><X size={13}/></button>}</div><button className="filter-btn" onClick={()=>toast("Filters will be available in the library update.")}><SlidersHorizontal size={16}/></button></div></div>
     <div className="game-grid">{filtered.map((g,i)=><article className="game-card" key={g.name}><div className={"game-art "+g.art}><span className="art-code">GV / 0{i+1}</span><strong>{g.mark}</strong><span className="art-bottom">{g.genre}</span><button className="star-btn" onClick={()=>toast(g.name+" saved to favorites.")}><Star size={15}/></button></div><div className="game-meta"><div><b>{g.name}</b><small>{g.studio}</small></div><span className="playtime">{g.time}</span></div><button className="game-action" onClick={()=>toast("Streaming is not connected yet. This is a UI preview.")}>{g.tag==="CONTINUE"?"RESUME TITLE":"VIEW DETAILS"} <ArrowUpRight size={14}/></button></article>)}</div>
     {filtered.length===0&&<div className="empty">No titles match “{query}”.</div>}
    </section>
   </div>:<div className="subpage"><div className="eyebrow">GAMEVAULT MODULE</div><h1>{tab}</h1><p>This section is being prepared as part of the original GameVault experience.</p><div className="module-card"><div className="module-icon">{tab==="Controller"?<Gamepad2/>:<Gauge/>}</div><div><b>{tab==="Controller"?"Controller center":"Performance lab"}</b><small>{tab==="Controller"?"Pair a controller and configure your preferred input layout.":"Review stream quality, latency, and connection health during a session."}</small></div><span className="coming">COMING NEXT</span></div></div>}
   <footer><span>GAMEVAULT CLOUD <i>BUILD 0.1.0 / UI PREVIEW</i></span><span>INDEPENDENT PROJECT <span className="footer-dot">●</span> NOT AFFILIATED WITH NVIDIA</span></footer>
  </main>
  {showSettings&&<div className="modal-backdrop" onClick={()=>setShowSettings(false)}><div className="settings-modal" onClick={e=>e.stopPropagation()}><div className="modal-head"><div><div className="eyebrow">PREFERENCES</div><h2>Quick settings</h2></div><button className="icon-btn" onClick={()=>setShowSettings(false)}><X/></button></div><label>STREAM PROFILE <span>Preview only</span></label><div className="profile-options">{["Quality","Balanced","Performance"].map(p=><button key={p} className={profile===p?"selected":""} onClick={()=>setProfile(p)}>{p}{profile===p&&<Check size={14}/>}</button>)}</div><div className="setting-row"><div><b>Controller support</b><small>Configure input after connecting a device</small></div><Gamepad2/></div><div className="setting-row"><div><b>Network diagnostics</b><small>Metrics appear during an active stream</small></div><Wifi/></div><button className="primary-btn full" onClick={()=>{setShowSettings(false);toast("Preferences saved locally for this preview.")}}>SAVE PREFERENCES</button></div></div>}
  {notice&&<div className="toast"><Check size={16}/>{notice}</div>}
 </div>
}
export default App;