import { Globe, User, Mail, Lock, EyeOff, MonitorSmartphone } from "lucide-react";
import { Link } from "react-router-dom";

export default function Signup() {
  return (
    <div className="min-h-screen bg-[#0a0a0a] flex flex-col relative overflow-x-hidden antialiased">
      {/* Background */}
      <div 
        className="absolute inset-0 bg-cover bg-center opacity-20 mix-blend-screen pointer-events-none"
        style={{ 
          backgroundImage: `url("https://images.unsplash.com/photo-1534447677768-be436bb09401?ixlib=rb-4.0.3&auto=format&fit=crop&w=2000&q=80")` 
        }}
      />
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_20%_30%,rgba(0,242,255,0.15)_0%,transparent_40%),radial-gradient(circle_at_80%_70%,rgba(115,24,255,0.15)_0%,transparent_40%),linear-gradient(180deg,rgba(10,10,10,1)_0%,rgba(10,10,10,1)_100%)] z-0 opacity-80 pointer-events-none"></div>

      <main className="flex-grow flex items-center justify-center p-4 md:p-8 z-10 relative">
        <div className="w-full max-w-[480px]">
          
          <div className="text-center mb-10">
            <Globe className="text-primary-container mx-auto mb-4 drop-shadow-[0_0_15px_rgba(0,242,255,0.8)]" size={48} strokeWidth={1.5} />
            <h1 className="font-space font-bold text-[40px] leading-none text-on-background mb-3 tracking-tighter">
              COSMIC_LINGUA
            </h1>
            <p className="font-manrope text-on-surface-variant text-[17px]">
              Begin your linguistic journey across the cosmos.
            </p>
          </div>

          <div className="bg-black/40 backdrop-blur-2xl rounded-2xl p-8 shadow-[0_20px_50px_rgba(0,0,0,0.5)] border border-white/10">
            <form className="space-y-6">
              
              <div className="space-y-2 relative">
                <label className="font-space font-semibold text-[11px] text-on-surface-variant block uppercase tracking-widest">
                  Full Name
                </label>
                <div className="relative group">
                  <User className="absolute left-4 top-1/2 -translate-y-1/2 text-outline group-focus-within:text-primary-container transition-colors" size={20} />
                  <input 
                    type="text" 
                    placeholder="Jane Doe" 
                    className="w-full bg-surface-container-high border-b-2 border-outline-variant text-on-background font-manrope px-4 py-4 pl-12 focus:outline-none focus:border-primary-container focus:shadow-[0_0_10px_rgba(0,242,255,0.2)] rounded-t-lg transition-all"
                  />
                </div>
              </div>

              <div className="space-y-2 relative">
                <label className="font-space font-semibold text-[11px] text-on-surface-variant block uppercase tracking-widest">
                  Comm Channel (Email)
                </label>
                <div className="relative group">
                  <Mail className="absolute left-4 top-1/2 -translate-y-1/2 text-outline group-focus-within:text-primary-container transition-colors" size={20} />
                  <input 
                    type="email" 
                    placeholder="jane@orbit.net" 
                    className="w-full bg-surface-container-high border-b-2 border-outline-variant text-on-background font-manrope px-4 py-4 pl-12 focus:outline-none focus:border-primary-container focus:shadow-[0_0_10px_rgba(0,242,255,0.2)] rounded-t-lg transition-all"
                  />
                </div>
              </div>

              <div className="space-y-2 relative">
                <label className="font-space font-semibold text-[11px] text-on-surface-variant block uppercase tracking-widest">
                  Access Key (Password)
                </label>
                <div className="relative group">
                  <Lock className="absolute left-4 top-1/2 -translate-y-1/2 text-outline group-focus-within:text-primary-container transition-colors" size={20} />
                  <input 
                    type="password" 
                    placeholder="••••••••" 
                    className="w-full bg-surface-container-high border-b-2 border-outline-variant text-on-background font-manrope px-4 py-4 pl-12 tracking-widest focus:outline-none focus:border-primary-container focus:shadow-[0_0_10px_rgba(0,242,255,0.2)] rounded-t-lg transition-all"
                  />
                  <button type="button" className="absolute right-4 top-1/2 -translate-y-1/2 text-outline hover:text-primary-container transition-colors">
                    <EyeOff size={20} />
                  </button>
                </div>
              </div>

              <div className="pt-4">
                <Link 
                  to="/" 
                  className="w-full block text-center bg-surface-tint text-on-primary font-space font-bold py-4 rounded-xl uppercase tracking-widest hover:bg-primary-fixed transition-all duration-300 shadow-[0_0_15px_rgba(0,242,255,0.3)] hover:shadow-[0_0_25px_rgba(0,242,255,0.5)]"
                >
                  KAYDOL
                </Link>
              </div>

            </form>

            <div className="mt-8 relative flex items-center justify-center">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-outline-variant"></div>
              </div>
              <span className="relative bg-[#171717] px-4 font-space font-semibold text-[10px] text-outline uppercase tracking-widest">
                Or Link Neural Net
              </span>
            </div>

            <div className="mt-8 grid grid-cols-2 gap-4">
              <button type="button" className="flex items-center justify-center gap-2 bg-white/5 border border-white/10 py-3 px-4 rounded-xl hover:bg-white/10 transition-colors">
                <Globe className="text-on-background" size={18} />
                <span className="font-space font-semibold text-sm text-on-background">Google</span>
              </button>
              <button type="button" className="flex items-center justify-center gap-2 bg-white/5 border border-white/10 py-3 px-4 rounded-xl hover:bg-white/10 transition-colors">
                <MonitorSmartphone className="text-on-background" size={18} />
                <span className="font-space font-semibold text-sm text-on-background">Apple</span>
              </button>
            </div>

            <div className="mt-8 text-center">
              <p className="font-manrope text-on-surface-variant">
                Already in orbit? <Link to="/login" className="text-primary-container hover:text-primary-fixed transition-colors underline decoration-primary-container/30 underline-offset-4">Sign in here</Link>.
              </p>
            </div>

          </div>
        </div>
      </main>

    </div>
  );
}
