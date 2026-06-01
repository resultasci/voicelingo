import { useState } from "react";
import { User, Bell, Settings as SettingsIcon, Pencil, LogOut, ArrowLeft, ChevronDown } from "lucide-react";
import { Link } from "react-router-dom";

export default function Settings() {
  const [dailyMissions, setDailyMissions] = useState(true);
  const [systemUpdates, setSystemUpdates] = useState(false);

  return (
    <div className="flex-grow w-full max-w-[800px] mx-auto px-4 md:px-8 py-6 relative">
      
      {/* Mobile Top Bar Override */}
      <div className="md:hidden fixed top-0 left-0 w-full z-[60] flex justify-between items-center px-6 h-16 bg-black/70 backdrop-blur-xl border-b border-primary-container/20 shadow-[0_4px_30px_rgba(0,242,255,0.1)]">
        <Link to="/" className="text-primary-container hover:text-primary transition-colors">
          <ArrowLeft size={24} />
        </Link>
        <h1 className="font-space tracking-widest uppercase text-sm font-bold text-primary-container drop-shadow-[0_0_12px_rgba(0,242,255,0.8)]">
          AYARLAR
        </h1>
        <div className="text-primary-container opacity-0 pointer-events-none">
          <User size={24} />
        </div>
      </div>

      <div className="mt-6 md:mt-0 space-y-6">
        
        {/* Account Section */}
        <section className="glass-panel rounded-2xl p-6 md:p-8">
          <div className="flex items-center mb-6">
            <User className="text-primary-container mr-3 drop-shadow-[0_0_8px_rgba(0,242,255,0.6)]" size={28} />
            <h2 className="font-space font-medium text-2xl text-primary-container text-shadow-neon-primary">Account</h2>
          </div>
          
          <div className="space-y-5">
            <div className="flex flex-col">
              <label className="font-space font-semibold text-xs tracking-widest text-primary-container/70 mb-2 uppercase">
                Email Address
              </label>
              <input 
                type="email" 
                readOnly 
                value="commander@orbit.com" 
                className="neon-input rounded-xl text-on-surface font-space font-medium p-3 w-full opacity-80 cursor-not-allowed"
              />
            </div>
            
            <div className="flex flex-col relative w-full">
              <label className="font-space font-semibold text-xs tracking-widest text-primary-container/70 mb-2 uppercase">
                Password
              </label>
              <div className="relative group">
                <input 
                  type="password" 
                  value="********" 
                  readOnly
                  className="neon-input rounded-xl text-on-surface font-space font-medium p-3 w-full pr-12 w-full"
                />
                <button className="absolute right-4 top-1/2 -translate-y-1/2 text-primary-container/50 group-hover:text-primary-container transition-colors">
                  <Pencil size={18} />
                </button>
              </div>
            </div>
          </div>
        </section>

        {/* Communications Section */}
        <section className="glass-panel rounded-2xl p-6 md:p-8">
          <div className="flex items-center mb-6">
            <Bell className="text-primary-container mr-3 drop-shadow-[0_0_8px_rgba(0,242,255,0.6)] fill-primary-container/20" size={28} />
            <h2 className="font-space font-medium text-2xl text-primary-container text-shadow-neon-primary">Communications</h2>
          </div>
          
          <div className="space-y-4">
            <div className="flex justify-between items-center py-2 border-b border-primary-container/10">
              <div>
                <p className="font-space font-medium text-lg text-on-surface">Daily Missions</p>
                <p className="font-space font-medium text-xs tracking-widest text-primary-container/60 mt-1 uppercase">Reminders for learning streaks</p>
              </div>
              
              <button 
                onClick={() => setDailyMissions(!dailyMissions)}
                className={`w-14 h-7 rounded-full transition-colors relative flex items-center shrink-0 border ${dailyMissions ? 'bg-primary-container/20 border-primary-container shadow-[0_0_10px_rgba(0,242,255,0.2)_inset]' : 'bg-surface-container-high border-outline'}`}
              >
                <div className={`w-5 h-5 rounded-full bg-outline absolute transition-transform duration-300 left-1 ${dailyMissions ? 'translate-x-7 bg-primary-container shadow-[0_0_8px_#00f2ff]' : 'translate-x-0'}`} />
              </button>
            </div>

            <div className="flex justify-between items-center py-2">
              <div>
                <p className="font-space font-medium text-lg text-on-surface">System Updates</p>
                <p className="font-space font-medium text-xs tracking-widest text-primary-container/60 mt-1 uppercase">New galaxy expansions and features</p>
              </div>
              
              <button 
                onClick={() => setSystemUpdates(!systemUpdates)}
                className={`w-14 h-7 rounded-full transition-colors relative flex items-center shrink-0 border ${systemUpdates ? 'bg-primary-container/20 border-primary-container shadow-[0_0_10px_rgba(0,242,255,0.2)_inset]' : 'bg-surface-container-high border-outline'}`}
              >
                <div className={`w-5 h-5 rounded-full bg-outline absolute transition-transform duration-300 left-1 ${systemUpdates ? 'translate-x-7 bg-primary-container shadow-[0_0_8px_#00f2ff]' : 'translate-x-0'}`} />
              </button>
            </div>
          </div>
        </section>

        {/* System Preferences */}
        <section className="glass-panel rounded-2xl p-6 md:p-8">
          <div className="flex items-center mb-6">
            <SettingsIcon className="text-primary-container mr-3 drop-shadow-[0_0_8px_rgba(0,242,255,0.6)]" size={28} />
            <h2 className="font-space font-medium text-2xl text-primary-container text-shadow-neon-primary">System Preferences</h2>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 w-full">
            <div className="flex flex-col relative">
              <label className="font-space font-semibold text-xs tracking-widest text-primary-container/70 mb-2 uppercase">
                Interface Language
              </label>
              <div className="relative">
                <select className="neon-input rounded-xl text-on-surface font-space font-medium p-3.5 w-full appearance-none cursor-pointer">
                  <option value="en">English (Earth)</option>
                  <option value="tr" selected>Türkçe (Orion)</option>
                </select>
                <ChevronDown className="absolute right-4 top-1/2 -translate-y-1/2 text-primary-container/50 pointer-events-none" size={20} />
              </div>
            </div>

            <div className="flex flex-col relative">
              <label className="font-space font-semibold text-xs tracking-widest text-primary-container/70 mb-2 uppercase">
                Visual Theme
              </label>
              <div className="relative">
                <select className="neon-input rounded-xl text-on-surface font-space font-medium p-3.5 w-full appearance-none cursor-pointer">
                  <option value="dark" selected>Obsidian Void (Dark)</option>
                  <option value="light">Solar Flare (Light)</option>
                </select>
                <ChevronDown className="absolute right-4 top-1/2 -translate-y-1/2 text-primary-container/50 pointer-events-none" size={20} />
              </div>
            </div>
          </div>
        </section>

        {/* Disconnect Button */}
        <div className="flex justify-center pt-6 pb-12">
          <Link to="/login" className="bg-transparent border border-error text-error px-8 py-3 rounded-full font-space font-bold uppercase tracking-widest text-sm hover:bg-error/10 hover:shadow-[0_0_15px_rgba(255,180,171,0.3)] transition-all duration-300 flex items-center gap-3">
             <LogOut size={20} />
             DISCONNECT
          </Link>
        </div>

      </div>
    </div>
  );
}
