import { Search, CheckCircle2, RefreshCw, Sparkles } from "lucide-react";
import { cn } from "../lib/utils";

export default function Vocabulary() {
  const categories = ["Tümü", "Pratik Gerekenler", "Öğrenilenler", "Favoriler"];

  const words = [
    {
      word: "Resilience",
      pronunciation: "/rɪˈzɪliəns/",
      translation: "Direnç, Esneklik",
      example: '"The system demonstrated high resilience against structural anomalies."',
      status: "Pratik",
      statusColor: "text-secondary-fixed",
      bgColor: "bg-secondary-container",
      progress: 45,
    },
    {
      word: "Ephemeral",
      pronunciation: "/ɪˈfemərəl/",
      translation: "Geçici, Kısa süreli",
      example: '"The cosmic phenomena was beautiful but entirely ephemeral."',
      status: "Öğrenildi",
      statusColor: "text-primary-fixed",
      bgColor: "bg-primary-fixed",
      progress: 100,
    },
    {
      word: "Ubiquitous",
      pronunciation: "/juːˈbɪkwɪtəs/",
      translation: "Her yerde bulunan",
      example: '"Artificial intelligence has become ubiquitous in modern orbital stations."',
      status: "Süreçte",
      statusColor: "text-tertiary-fixed",
      bgColor: "bg-tertiary-fixed",
      progress: 70,
    },
    {
      word: "Paradigm",
      pronunciation: "/ˈpærədaɪm/",
      translation: "Paradigma, Model",
      example: '"A fundamental shift in the scientific paradigm is required."',
      status: "Yeni",
      statusColor: "text-surface-tint",
      bgColor: "bg-surface-tint",
      progress: 10,
    },
  ];

  return (
    <div className="flex-grow max-w-[1280px] w-full mx-auto px-4 md:px-8 pt-8 md:pt-12 pb-24">
      {/* Header Section */}
      <div className="mb-8">
        <h1 className="font-space font-semibold text-3xl md:text-4xl text-primary drop-shadow-[0_0_12px_rgba(225,253,255,0.2)] mb-2 tracking-tight">
          Kelime Kütüphanesi
        </h1>
        <p className="font-manrope text-on-surface-variant max-w-2xl text-lg">
          Terminal veritabanına erişildi. Bilişsel sözlük genişletilmeye hazır.
        </p>
      </div>

      {/* Search Bar */}
      <div className="relative w-full mb-8 group">
        <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
          <Search className="text-outline group-focus-within:text-surface-tint transition-colors" size={20} />
        </div>
        <input 
          type="text" 
          placeholder="Kelime veya çeviri ara..." 
          className="w-full bg-surface-container-high/80 backdrop-blur-md border-b-2 border-outline-variant text-on-surface placeholder-on-surface-variant font-manrope rounded-t-lg py-4 pl-12 pr-4 focus:outline-none focus:border-surface-tint focus:ring-1 focus:ring-surface-tint focus:bg-surface-container transition-all shadow-[0_4px_30px_rgba(0,0,0,0.1)]" 
        />
      </div>

      {/* Category Filters */}
      <div className="flex overflow-x-auto gap-4 mb-8 scrollbar-hide snap-x pb-2">
        {categories.map((cat, idx) => (
          <button 
            key={idx}
            className={cn(
              "snap-start whitespace-nowrap px-6 py-2 rounded-full border font-space font-semibold tracking-wider text-xs md:text-sm transition-all",
              idx === 0 
                ? "border-surface-tint bg-surface-tint/10 text-surface-tint shadow-[0_0_15px_rgba(0,219,231,0.2)]"
                : "border-outline-variant hover:border-outline bg-surface-container/50 text-on-surface-variant hover:text-on-surface"
            )}
          >
            {cat}
          </button>
        ))}
      </div>

      {/* Word Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {words.map((item, idx) => (
          <div key={idx} className={cn(
            "glass-panel rounded-xl p-6 relative group transition-colors duration-300 flex flex-col justify-between min-h-[220px]",
            item.status === "Pratik" && "hover:border-secondary-container/50",
            item.status === "Öğrenildi" && "hover:border-primary-fixed/50",
            item.status === "Süreçte" && "hover:border-tertiary-fixed/50",
            item.status === "Yeni" && "hover:border-surface-tint/50"
          )}>
            <div className={cn(
              "absolute top-0 right-0 w-32 h-32 rounded-full blur-2xl -mr-10 -mt-10 pointer-events-none opacity-20",
              item.bgColor
            )}></div>
            
            <div className="flex justify-between items-start mb-4">
              <div>
                <h3 className="font-space font-medium text-2xl text-primary tracking-wide mb-1">
                  {item.word}
                </h3>
                <span className="font-space text-xs uppercase opacity-80 font-mono tracking-widest" style={{ color: "var(--color-surface-tint)"}}>
                  {item.pronunciation}
                </span>
              </div>
              
              {/* Status Chip */}
              <div className={cn(
                "px-3 py-1 rounded-full border bg-opacity-10 flex items-center gap-1.5",
                item.status === "Pratik" && "border-secondary-container/30 bg-secondary-container/10 shadow-[0_0_8px_rgba(255,94,7,0.15)]",
                item.status === "Öğrenildi" && "border-primary-fixed/30 bg-primary-fixed/10 shadow-[0_0_8px_rgba(116,245,255,0.15)]",
                item.status === "Süreçte" && "border-tertiary-fixed/30 bg-tertiary-fixed/10 shadow-[0_0_8px_rgba(233,221,255,0.15)]",
                item.status === "Yeni" && "border-surface-tint/30 bg-surface-tint/10"
              )}>
                {item.status === "Pratik" && <div className="w-1.5 h-1.5 rounded-full bg-secondary-container animate-pulse" />}
                {item.status === "Öğrenildi" && <CheckCircle2 size={12} className="text-primary-fixed" />}
                {item.status === "Süreçte" && <RefreshCw size={12} className="text-tertiary-fixed animate-spin-slow" />}
                {item.status === "Yeni" && <Sparkles size={12} className="text-surface-tint" />}
                <span className={cn("font-space text-[10px] font-bold uppercase", item.statusColor)}>
                  {item.status}
                </span>
              </div>
            </div>
            
            <div className="mb-6 z-10">
              <p className="font-manrope text-lg text-on-surface mb-2">{item.translation}</p>
              <p className="font-manrope text-on-surface-variant/70 italic text-sm">{item.example}</p>
            </div>
            
            <div className="mt-auto w-full bg-surface-container-highest rounded-full h-1.5 overflow-hidden z-10">
              <div 
                className={cn("h-full rounded-full shadow-[0_0_5px_currentColor]", item.bgColor)} 
                style={{ width: `${item.progress}%` }} 
              />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
