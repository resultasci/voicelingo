import { Award, Globe, Rocket, Brain, Flame, Languages } from "lucide-react";
import { cn } from "../lib/utils";

export default function Profile() {
  return (
    <div className="flex-grow w-full max-w-[1000px] mx-auto px-4 md:px-8 py-8 md:py-12">
      
      {/* Profile Header */}
      <section className="flex flex-col items-center justify-center mb-12">
        <div className="relative mb-6 group cursor-pointer">
          <div className="absolute inset-0 rounded-full border-2 border-primary-container/50 scale-110 shadow-[0_0_20px_rgba(0,242,255,0.3)] transition-transform duration-500 group-hover:scale-125 group-hover:rotate-180 border-dashed"></div>
          <img 
            src="https://lh3.googleusercontent.com/aida-public/AB6AXuCBKxMl7mEjBEsqXov1KyamQiEha7Ab7NKaaS1SSeIxbq6WV0C9InaiC5sTvMzVSr3YPTlRx467Kh-ICm3SNVbsUZ7ACw3RHFr1jzUgFSBzIeyoswB4bUwkk2UwLdNcIG2HALtUM7v1ZBGu__h5NJXViYMSk9AQ2YcZyPDxcfYXaKkGivl2T-4Mwj7DaOil-RSNzi5cpTMz9NfnV_JY55ehM9-5XpuXO-QqLAEgb3tKsuk7JvzqElC1217nfWQzfyHMq5pniwa5eX2b" 
            alt="Commander Profile" 
            className="w-28 h-28 md:w-32 md:h-32 rounded-full relative z-10 border-2 border-primary-container/30 object-cover shadow-[0_0_30px_rgba(0,242,255,0.2)] bg-surface-container"
          />
        </div>
        <h1 className="font-space font-bold text-3xl md:text-4xl text-white mb-2 tracking-widest drop-shadow-[0_0_10px_rgba(255,255,255,0.2)] uppercase">
          Kumandan Eren
        </h1>
        <div className="flex items-center gap-2 text-outline font-space text-sm font-semibold tracking-wide">
          <Award size={16} className="text-primary-container" />
          <span>Seviye 42 • Galaktik Dilbilimci</span>
        </div>
      </section>

      {/* Stats Grid */}
      <section className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
        {/* Streak */}
        <div className="glass-panel rounded-2xl p-6 flex flex-col items-center justify-center relative overflow-hidden group hover:border-secondary-container/40 transition-colors">
          <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-secondary-container to-transparent"></div>
          <Flame size={40} className="text-secondary-container my-3 group-hover:scale-110 transition-transform duration-300 drop-shadow-[0_0_8px_rgba(255,94,7,0.5)] fill-secondary" />
          <span className="font-space font-bold text-5xl text-white mb-1 tracking-tighter">14</span>
          <span className="font-space text-xs font-bold text-outline-variant uppercase tracking-widest">Günlük Seri</span>
        </div>

        {/* Words Learned */}
        <div className="glass-panel rounded-2xl p-6 flex flex-col items-center justify-center relative overflow-hidden group hover:border-primary-container/40 transition-colors">
          <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-primary-container to-transparent"></div>
          <Languages size={40} className="text-primary-container my-3 group-hover:scale-110 transition-transform duration-300 drop-shadow-[0_0_8px_rgba(0,242,255,0.5)]" />
          <span className="font-space font-bold text-5xl text-white mb-1 tracking-tighter">8,402</span>
          <span className="font-space text-xs font-bold text-outline-variant uppercase tracking-widest">Öğrenilen Kelime</span>
        </div>

        {/* Fluency Score */}
        <div className="glass-panel rounded-2xl p-6 flex flex-col items-center justify-center relative overflow-hidden group hover:border-on-tertiary-container/40 transition-colors">
          <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-on-tertiary-container to-transparent"></div>
          <Brain size={40} className="text-on-tertiary-container my-3 group-hover:scale-110 transition-transform duration-300 drop-shadow-[0_0_8px_rgba(115,24,255,0.5)] fill-on-tertiary-container/20" />
          <span className="font-space font-bold text-5xl text-white mb-1 tracking-tighter">%87</span>
          <span className="font-space text-xs font-bold text-outline-variant uppercase tracking-widest">Akıcılık Skoru</span>
        </div>
      </section>

      {/* Achievements Section */}
      <section>
        <h2 className="font-space text-2xl font-medium text-white mb-6 flex items-center gap-3">
          <Award className="text-primary-container" size={28} />
          Rozetler & Başarılar
        </h2>
        
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 md:gap-6">
          {/* Badge 1: Earned */}
          <div className="glass-panel border-white/5 rounded-xl p-5 flex flex-col items-center text-center opacity-100 hover:bg-white/5 transition-colors cursor-pointer group">
            <div className="w-16 h-16 rounded-full bg-surface-container-high flex items-center justify-center mb-4 border border-primary-container/40 shadow-[0_0_15px_rgba(0,242,255,0.2)] group-hover:shadow-[0_0_25px_rgba(0,242,255,0.4)] transition-all">
              <Rocket className="text-primary-container fill-primary-container/20" size={32} />
            </div>
            <span className="font-space font-bold text-sm text-white mb-1 tracking-wide">İlk Temas</span>
            <span className="font-manrope text-xs text-outline">100 Kelime</span>
          </div>

          {/* Badge 2: Earned */}
          <div className="glass-panel border-white/5 rounded-xl p-5 flex flex-col items-center text-center opacity-100 hover:bg-white/5 transition-colors cursor-pointer group">
            <div className="w-16 h-16 rounded-full bg-surface-container-high flex items-center justify-center mb-4 border border-secondary-container/40 shadow-[0_0_15px_rgba(255,94,7,0.2)] group-hover:shadow-[0_0_25px_rgba(255,94,7,0.4)] transition-all">
              <Globe className="text-secondary-container" size={32} />
            </div>
            <span className="font-space font-bold text-sm text-white mb-1 tracking-wide">Dünya Vatandaşı</span>
            <span className="font-manrope text-xs text-outline">B1 Seviyesi</span>
          </div>

          {/* Badge 3: Locked */}
          <div className="glass-panel border-transparent rounded-xl p-5 flex flex-col items-center text-center opacity-40 grayscale hover:grayscale-0 transition-all cursor-not-allowed">
            <div className="w-16 h-16 rounded-full bg-surface-container flex items-center justify-center mb-4 border border-white/10">
              <Award className="text-outline" size={32} />
            </div>
            <span className="font-space font-bold text-sm text-outline-variant mb-1 tracking-wide">Usta Çevirmen</span>
            <span className="font-manrope text-xs text-outline-variant/60 uppercase">Kilitli</span>
          </div>

          {/* Badge 4: Locked */}
          <div className="glass-panel border-transparent rounded-xl p-5 flex flex-col items-center text-center opacity-40 grayscale hover:grayscale-0 transition-all cursor-not-allowed">
            <div className="w-16 h-16 rounded-full bg-surface-container flex items-center justify-center mb-4 border border-white/10">
              <Globe className="text-outline" size={32} />
            </div>
            <span className="font-space font-bold text-sm text-outline-variant mb-1 tracking-wide">Evrensel Akıcılık</span>
            <span className="font-manrope text-xs text-outline-variant/60 uppercase">Kilitli</span>
          </div>
        </div>
      </section>

    </div>
  );
}
