import { Link, Outlet, useLocation } from "react-router-dom";
import {
  LayoutDashboard,
  BookOpen,
  MessageSquare,
  User,
  Settings,
} from "lucide-react";
import { cn } from "../lib/utils";

export default function Layout() {
  const location = useLocation();

  const navItems = [
    { label: "GENEL", path: "/", icon: LayoutDashboard },
    { label: "KELİME", path: "/vocabulary", icon: BookOpen },
    { label: "PRATİK", path: "/practice", icon: MessageSquare },
    { label: "PROFİL", path: "/profile", icon: User },
  ];

  return (
    <div className="min-h-screen flex flex-col font-manrope star-field">
      {/* Top App Bar */}
      <header className="fixed top-0 w-full z-50 border-b border-white/10 bg-black/70 backdrop-blur-xl flex justify-between items-center px-6 py-3">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-full overflow-hidden border border-primary-container/40 relative shrink-0">
             <img 
               src="https://lh3.googleusercontent.com/aida-public/AB6AXuArWiDrfgY3MqINyc4zxX9Ym11g6l0xtyxDMUqc0RcDCC5yolE9FYL83dclBM-6SEKnNBEYdCazY24cfXaN6WVkgJyTUwCAX3wfzUrMorkv9r6QQHTGwwjnJHAI6wOkRJX83AZzwcoEZkRWJWSBSrS-yr63ZLpaP9OYR8J_nAvSP_Oyhjg6WXk0qkDf9FwO2A4PUMqWoED2yoQWDg58Dei2hUjsoFTnQVDiHI0b67C_lwYa0jZHJ9Rf6Tij-W8NWrVrbHIouQCchZQ0" 
               alt="User Avatar" 
               className="w-full h-full object-cover"
             />
          </div>
          <span className="text-primary-container font-space font-bold text-xl tracking-tighter drop-shadow-[0_0_8px_rgba(0,242,255,0.5)] uppercase">
            COSMOS
          </span>
        </div>
        <Link 
          to="/settings"
          className={cn(
            "text-outline hover:text-primary-container transition-colors",
            location.pathname === "/settings" && "text-primary-container drop-shadow-[0_0_8px_rgba(0,242,255,0.5)]"
          )}
        >
          <Settings size={28} strokeWidth={1.5} />
        </Link>
      </header>

      {/* Main Responsive Canvas */}
      <div className="flex-grow flex w-full pt-[64px] pb-[80px] md:pb-0 md:pl-[80px]">
        
        {/* Desktop Side Nav */}
        <aside className="hidden md:flex fixed left-0 top-[64px] bottom-0 w-[80px] border-r border-white/10 bg-black/50 backdrop-blur-xl flex-col items-center pt-8 pb-8 z-40 gap-8">
           {navItems.map((item) => {
              const isActive = location.pathname === item.path;
              return (
                <Link
                  key={item.path}
                  to={item.path}
                  className={cn(
                    "flex flex-col items-center justify-center p-2 rounded-xl transition-all group",
                    isActive 
                      ? "text-primary-container drop-shadow-[0_0_10px_rgba(0,242,255,0.6)]" 
                      : "text-outline hover:text-primary-fixed"
                  )}
                >
                   <item.icon className={cn("transition-transform group-hover:scale-110", isActive && "fill-primary-container/20")} strokeWidth={isActive ? 2 : 1.5} size={28} />
                   <span className="font-space text-[9px] uppercase tracking-widest mt-1.5 opacity-0 group-hover:opacity-100 transition-opacity absolute translate-y-10 bg-surface px-2 py-0.5 rounded-md border border-white/5">
                     {item.label}
                   </span>
                </Link>
              );
           })}
        </aside>

        {/* Page Content */}
        <main className="flex-grow w-full h-full flex flex-col">
          <Outlet />
        </main>

      </div>

      {/* Mobile Bottom Nav */}
      <nav className="md:hidden fixed bottom-0 left-0 w-full z-50 border-t border-white/10 rounded-t-2xl bg-black/80 backdrop-blur-2xl shadow-[0_-4px_30px_rgba(0,0,0,0.5)] flex justify-around items-center px-2 pb-6 pt-3">
        {navItems.map((item) => {
          const isActive = location.pathname === item.path;
          return (
            <Link
              key={item.path}
              to={item.path}
              className={cn(
                "flex flex-col items-center justify-center w-20 transition-all duration-300",
                isActive 
                  ? "text-primary-container drop-shadow-[0_0_10px_rgba(0,242,255,0.6)] translate-y-[-4px]" 
                  : "text-outline hover:text-primary"
              )}
            >
              <item.icon 
                className={cn("mb-1", isActive && "fill-primary-container/20")} 
                size={24} 
                strokeWidth={isActive ? 2 : 1.5} 
              />
              <span className={cn(
                "font-space text-[10px] uppercase tracking-wider transition-all",
                isActive ? "font-bold" : "opacity-70 font-medium"
              )}>
                {item.label}
              </span>
            </Link>
          );
        })}
      </nav>
    </div>
  );
}
