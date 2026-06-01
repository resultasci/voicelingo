import { Flame, Star, Bot, Rocket, Play } from "lucide-react";
import { cn } from "../lib/utils";

export default function Dashboard() {
  return (
    <div className="flex-grow max-w-[1280px] w-full mx-auto px-4 md:px-8 pt-8 md:pt-12 flex flex-col gap-8">
      {/* Welcome Section */}
      <section>
        <h1 className="font-space font-bold text-3xl md:text-4xl text-primary drop-shadow-[0_0_8px_rgba(225,253,255,0.3)] tracking-tight">
          Merhaba, Kaptan
        </h1>
        <p className="font-manrope text-on-surface-variant mt-2 text-lg">
          Günlük galaktik hedeflerine hazır mısın?
        </p>
      </section>

      {/* Telemetry HUD */}
      <section className="grid grid-cols-2 gap-4 md:gap-6">
        <div className="glass-panel glass-panel-gradient-border rounded-xl p-4 flex flex-col md:flex-row items-start md:items-center gap-4">
          <div className="w-12 h-12 shrink-0 rounded-full bg-secondary-container/20 flex items-center justify-center border border-secondary/30 shadow-[0_0_15px_rgba(255,94,7,0.2)]">
            <Flame className="text-secondary fill-secondary" />
          </div>
          <div>
            <p className="font-space text-xs text-outline-variant font-semibold uppercase tracking-widest mb-1">
              Seri
            </p>
            <p className="font-space text-2xl md:text-3xl font-semibold text-secondary drop-shadow-[0_0_5px_rgba(255,181,154,0.5)] leading-none">
              14 Gün
            </p>
          </div>
        </div>
        
        <div className="glass-panel glass-panel-gradient-border rounded-xl p-4 flex flex-col md:flex-row items-start md:items-center gap-4">
          <div className="w-12 h-12 shrink-0 rounded-full bg-primary-container/20 flex items-center justify-center border border-primary-fixed-dim/30 shadow-[0_0_15px_rgba(0,242,255,0.2)]">
            <Star className="text-primary-fixed-dim fill-primary-fixed-dim" />
          </div>
          <div>
            <p className="font-space text-xs text-outline-variant font-semibold uppercase tracking-widest mb-1">
              XP Puanı
            </p>
            <p className="font-space text-2xl md:text-3xl font-semibold text-primary-fixed-dim drop-shadow-[0_0_5px_rgba(0,219,231,0.5)] leading-none">
              2,450
            </p>
          </div>
        </div>
      </section>

      {/* AI Practice Highlight Card */}
      <section className="glass-panel glass-panel-gradient-border rounded-2xl overflow-hidden relative group">
        <div className="absolute inset-0 bg-gradient-to-br from-tertiary-container/10 to-transparent opacity-50 z-0"></div>
        <div className="p-6 md:p-8 relative z-10 flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
          <div className="flex-1">
            <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-tertiary-container/10 border border-tertiary-fixed-dim/30 mb-4 shadow-[0_0_8px_rgba(209,188,255,0.2)]">
              <Bot className="text-tertiary-fixed-dim" size={14} />
              <span className="font-space text-xs font-semibold tracking-wider text-tertiary-fixed-dim uppercase">
                Yapay Zeka Modülü
              </span>
            </div>
            <h2 className="font-space text-2xl md:text-3xl font-medium text-tertiary mb-2 drop-shadow-[0_0_5px_rgba(252,245,255,0.5)]">
              Derin Uzay Pratiği
            </h2>
            <p className="font-manrope text-on-surface-variant max-w-[420px] leading-relaxed">
              Kişiselleştirilmiş AI asistanın ile günlük konuşma simülasyonunu başlat.
            </p>
          </div>
          <button className="w-full md:w-auto bg-surface-tint text-on-primary font-space font-semibold text-sm px-6 py-4 rounded-xl flex items-center justify-center gap-2 hover:shadow-[0_0_25px_rgba(0,219,231,0.5)] hover:bg-primary transition-all duration-300">
            <Rocket size={18} />
            SİMÜLASYONU BAŞLAT
          </button>
        </div>
        {/* Decorative orb */}
        <div className="absolute -bottom-16 -right-16 w-48 h-48 bg-tertiary-fixed-dim/20 rounded-full blur-3xl z-0 pointer-events-none group-hover:bg-tertiary-fixed-dim/30 transition-colors duration-700"></div>
      </section>

      {/* Daily Goals */}
      <section className="mb-8">
        <h3 className="font-space font-medium text-xl text-on-surface mb-5">Günlük Görevler</h3>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          
          <div className="glass-panel glass-panel-gradient-border rounded-xl p-4 md:p-5 flex items-center justify-between hover:bg-surface-variant/30 transition-colors cursor-pointer group">
            <div className="flex items-center gap-5">
              <div className="relative w-16 h-16 shrink-0">
                <svg className="w-full h-full -rotate-90 transform" viewBox="0 0 60 60">
                  <circle className="text-surface-variant" strokeWidth="4" stroke="currentColor" fill="transparent" r="26" cx="30" cy="30" />
                  <circle 
                    className="text-primary-container transition-all duration-1000 ease-out" 
                    strokeWidth="4" strokeDasharray="163" strokeDashoffset="40" strokeLinecap="round" stroke="currentColor" fill="transparent" r="26" cx="30" cy="30" 
                    style={{ filter: "drop-shadow(0 0 4px rgba(0,242,255,0.6))" }}
                  />
                </svg>
                <div className="absolute inset-0 flex items-center justify-center font-space font-bold text-sm text-primary-container">
                  75%
                </div>
              </div>
              <div>
                <h4 className="font-space font-medium text-lg text-primary tracking-wide">İngilizce</h4>
                <p className="font-space text-xs text-outline-variant uppercase tracking-wider mt-1 font-semibold">B2 • İleri Yörünge</p>
              </div>
            </div>
            <button className="w-10 h-10 rounded-full border border-primary-container/30 flex items-center justify-center text-primary-container group-hover:bg-primary-container/10 transition-colors shadow-[0_0_10px_rgba(0,242,255,0.1)]">
              <Play className="ml-1" size={18} fill="currentColor" />
            </button>
          </div>

          <div className="glass-panel glass-panel-gradient-border rounded-xl p-4 md:p-5 flex items-center justify-between hover:bg-surface-variant/30 transition-colors cursor-pointer group">
            <div className="flex items-center gap-5">
              <div className="relative w-16 h-16 shrink-0">
                <svg className="w-full h-full -rotate-90 transform" viewBox="0 0 60 60">
                  <circle className="text-surface-variant" strokeWidth="4" stroke="currentColor" fill="transparent" r="26" cx="30" cy="30" />
                  <circle 
                    className="text-tertiary-fixed-dim transition-all duration-1000 ease-out" 
                    strokeWidth="4" strokeDasharray="163" strokeDashoffset="114" strokeLinecap="round" stroke="currentColor" fill="transparent" r="26" cx="30" cy="30" 
                    style={{ filter: "drop-shadow(0 0 4px rgba(209,188,255,0.6))" }}
                  />
                </svg>
                <div className="absolute inset-0 flex items-center justify-center font-space font-bold text-sm text-tertiary-fixed-dim">
                  30%
                </div>
              </div>
              <div>
                <h4 className="font-space font-medium text-lg text-tertiary tracking-wide">İspanyolca</h4>
                <p className="font-space text-xs text-outline-variant uppercase tracking-wider mt-1 font-semibold">A1 • Yeni Keşif</p>
              </div>
            </div>
            <button className="w-10 h-10 rounded-full border border-tertiary-fixed-dim/30 flex items-center justify-center text-tertiary-fixed-dim group-hover:bg-tertiary-fixed-dim/10 transition-colors shadow-[0_0_10px_rgba(209,188,255,0.1)]">
              <Play className="ml-1" size={18} fill="currentColor" />
            </button>
          </div>

        </div>
      </section>
    </div>
  );
}
