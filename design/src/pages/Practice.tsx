import { Bot, Lightbulb, Keyboard, Mic, Globe } from "lucide-react";
import { cn } from "../lib/utils";

export default function Practice() {
  return (
    <div className="flex-grow flex flex-col w-full max-w-[1000px] mx-auto px-4 md:px-8 py-4 relative">
      
      {/* Chat Area */}
      <div className="flex-grow flex flex-col gap-6 overflow-y-auto mb-[100px] pr-2 pt-4">
        
        {/* AI Message */}
        <div className="flex gap-3 max-w-[85%] md:max-w-[70%] self-start">
          <div className="w-8 h-8 rounded-full bg-primary-container/20 border border-primary-container/50 flex items-center justify-center shrink-0 mt-1">
            <Bot className="text-primary-container" size={18} />
          </div>
          <div className="glass-panel p-4 md:p-5 rounded-2xl rounded-tl-sm">
            <p className="text-on-surface mb-3 leading-relaxed">
              Merhaba! Bugün İspanyolca pratiğimize "Seyahat" konusuyla devam edelim mi? Havaalanında geçen bir diyalog kurabiliriz.
            </p>
            <div className="flex gap-2 pt-3 border-t border-white/10">
              <button className="font-space text-xs font-semibold text-surface-tint hover:text-primary transition-colors flex items-center gap-1.5 uppercase tracking-wide">
                <Globe size={14} /> Çeviriyi Gör
              </button>
            </div>
          </div>
        </div>

        {/* User Message */}
        <div className="flex gap-3 max-w-[85%] md:max-w-[70%] self-end flex-row-reverse">
          <div className="w-8 h-8 rounded-full overflow-hidden border border-white/10 shrink-0 mt-1">
             <img 
               src="https://lh3.googleusercontent.com/aida-public/AB6AXuArWiDrfgY3MqINyc4zxX9Ym11g6l0xtyxDMUqc0RcDCC5yolE9FYL83dclBM-6SEKnNBEYdCazY24cfXaN6WVkgJyTUwCAX3wfzUrMorkv9r6QQHTGwwjnJHAI6wOkRJX83AZzwcoEZkRWJWSBSrS-yr63ZLpaP9OYR8J_nAvSP_Oyhjg6WXk0qkDf9FwO2A4PUMqWoED2yoQWDg58Dei2hUjsoFTnQVDiHI0b67C_lwYa0jZHJ9Rf6Tij-W8NWrVrbHIouQCchZQ0" 
               alt="User" 
               className="w-full h-full object-cover grayscale"
             />
          </div>
          <div className="bg-primary-container/10 border border-primary-container/30 p-4 md:p-5 rounded-2xl rounded-tr-sm">
            <p className="text-primary leading-relaxed">
              Hola. Sí, claro. ¿Dónde está mi equipaje?
            </p>
          </div>
        </div>

        {/* Grammar Tip / Feedback Card */}
        <div className="self-center w-full max-w-md my-2">
          <div className="glass-panel border-primary-container/30 shadow-[0_0_15px_rgba(0,242,255,0.1)] p-4 rounded-xl flex items-start gap-4">
            <div className="bg-tertiary-container/10 p-2.5 rounded-lg text-tertiary-fixed-dim shrink-0 border border-white/5">
              <Lightbulb size={20} />
            </div>
            <div>
              <h4 className="font-space font-bold text-sm text-primary-fixed mb-1.5 uppercase tracking-widest text-shadow-neon-primary">
                Mükemmel!
              </h4>
              <p className="text-on-surface-variant text-sm leading-relaxed">
                "¿Dónde está...?" (Nerede?) kalıbını doğru kullandın. Devam edelim.
              </p>
            </div>
          </div>
        </div>

        {/* AI Message 2 */}
        <div className="flex gap-3 max-w-[85%] md:max-w-[70%] self-start">
          <div className="w-8 h-8 rounded-full bg-primary-container/20 border border-primary-container/50 flex items-center justify-center shrink-0 mt-1">
            <Bot className="text-primary-container" size={18} />
          </div>
          <div className="glass-panel p-4 md:p-5 rounded-2xl rounded-tl-sm">
            <p className="text-on-surface mb-3 leading-relaxed">
              Tu equipaje está en la cinta número cuatro. (Bagajınız dört numaralı bantta.)
            </p>
            <p className="text-on-surface-variant text-sm mt-3 italic border-l-2 border-primary-container pl-3 py-1">
              Sıra sende: "Teşekkür ederim, çıkış nerede?" demeye çalış.
            </p>
          </div>
        </div>
      </div>

      {/* Fixed Input Area */}
      <div className="fixed bottom-[88px] md:bottom-8 left-4 right-4 md:left-1/2 md:-translate-x-1/2 md:w-[600px] glass-panel border-white/20 rounded-full p-1.5 flex items-center transition-all duration-300 z-40 shadow-[0_4px_20px_rgba(0,0,0,0.5)] focus-within:border-primary-container focus-within:shadow-[0_0_15px_rgba(0,242,255,0.3)] bg-surface-container-highest/80">
        <button className="p-3 text-outline hover:text-primary transition-colors rounded-full flex items-center justify-center">
          <Keyboard size={20} />
        </button>
        <input 
          type="text" 
          placeholder="Mesajınızı yazın veya konuşun..." 
          className="flex-grow bg-transparent border-none text-on-surface placeholder-on-surface-variant focus:ring-0 px-2 font-manrope outline-none h-full"
        />
        {/* Voice Command Button */}
        <button className="w-12 h-12 rounded-full bg-primary-container text-on-primary-container flex items-center justify-center relative hover:bg-primary transition-colors z-10 shrink-0 shadow-[0_0_15px_rgba(0,242,255,0.5)] cursor-pointer outline-none">
          <Mic fill="currentColor" size={24} />
          {/* Pulse Effect */}
          <div className="absolute inset-0 rounded-full border border-primary-container/50 opacity-100 scale-110 pointer-events-none animate-pulse"></div>
        </button>
      </div>

    </div>
  );
}
