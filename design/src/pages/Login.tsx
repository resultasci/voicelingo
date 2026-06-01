import { Mail, Lock } from "lucide-react";
import { Link } from "react-router-dom";

export default function Login() {
  return (
    <div className="min-h-screen bg-[#0a0a0a] flex items-center justify-center p-6 relative overflow-hidden">
      {/* Background Image / Effect */}
      <div 
        className="absolute inset-0 bg-cover bg-center bg-no-repeat opacity-40 mix-blend-screen pointer-events-none"
        style={{ 
          backgroundImage: `url("https://lh3.googleusercontent.com/aida-public/AB6AXuDC1DPuQsW_WkyCb8EByh0IRook-fD7oBjFOBeio7-GgbQSOzqUq-AFzwz8xLnEfYvZh6dIRcxyaQ7c7Io0KZVX5Y4WWVOfiLthC0LlbyttUa76qy2atm5HRTssXMV0-dA4dIF3IEzrE6f8AYnxrXS7jduRFOWDeNQoHAAf7tHFE23EW9qycUG4Y26Ai-zTZGmXqN2QOgbm-2POQz2RrM052hNulioR3KzqY3AwJwdEx1slU15FhlWZ3XxQB5viVQ3ZKfRLhCxqmEh2")` 
        }}
      />
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_50%,rgba(0,242,255,0.05)_0%,rgba(10,10,10,1)_70%)] pointer-events-none"></div>

      {/* Main Panel */}
      <div className="w-full max-w-md bg-black/40 backdrop-blur-2xl border border-white/10 rounded-2xl p-10 flex flex-col items-center relative z-10 shadow-[0_0_50px_rgba(0,0,0,0.8)] before:absolute before:inset-0 before:bg-gradient-to-br before:from-white/5 before:to-transparent before:pointer-events-none before:rounded-2xl">
        
        <div className="text-center mb-10 w-full">
          <h1 className="font-space font-bold text-5xl text-primary-container drop-shadow-[0_0_15px_rgba(0,242,255,0.6)] mb-3 tracking-tight">
            COSMOS
          </h1>
          <p className="font-manrope text-on-surface-variant text-[17px]">
            Initialize Communication Link
          </p>
        </div>

        <form className="w-full flex flex-col gap-6">
          <div className="flex flex-col gap-2 relative">
            <label className="font-space font-semibold text-xs tracking-widest text-on-surface-variant uppercase">
              Email Vector
            </label>
            <div className="relative group">
              <Mail className="absolute left-4 top-1/2 -translate-y-1/2 text-outline-variant group-focus-within:text-primary-container transition-colors" size={20} />
              <input 
                type="email" 
                placeholder="user@galaxy.net" 
                className="w-full bg-surface-container-highest border border-outline-variant rounded-xl py-4 pl-12 pr-4 font-manrope text-on-surface focus:outline-none focus:border-primary-container focus:shadow-[0_0_15px_rgba(0,242,255,0.3)] placeholder:text-outline-variant transition-all"
              />
            </div>
          </div>

          <div className="flex flex-col gap-2 relative">
            <label className="font-space font-semibold text-xs tracking-widest text-on-surface-variant uppercase">
              Security Code
            </label>
            <div className="relative group">
              <Lock className="absolute left-4 top-1/2 -translate-y-1/2 text-outline-variant group-focus-within:text-primary-container transition-colors" size={20} />
              <input 
                type="password" 
                placeholder="••••••••" 
                className="w-full bg-surface-container-highest border border-outline-variant rounded-xl py-4 pl-12 pr-4 font-manrope text-on-surface focus:outline-none focus:border-primary-container focus:shadow-[0_0_15px_rgba(0,242,255,0.3)] placeholder:text-outline-variant transition-all tracking-widest"
              />
            </div>
          </div>

          <Link 
            to="/" 
            className="w-full bg-primary-container text-on-primary-fixed font-space font-bold text-sm uppercase tracking-widest py-4 rounded-xl mt-4 hover:bg-primary-fixed transition-all text-center shadow-[0_0_20px_rgba(0,242,255,0.3)] hover:shadow-[0_0_30px_rgba(0,242,255,0.6)] hover:-translate-y-0.5 block"
          >
            GİRİŞ YAP
          </Link>

          <div className="flex flex-col sm:flex-row justify-between items-center mt-6 gap-4 w-full">
            <a href="#" className="font-space font-semibold text-xs tracking-widest text-outline-variant hover:text-primary-container transition-colors uppercase">
              Forgot password?
            </a>
            <Link to="/signup" className="font-space font-semibold text-xs tracking-widest text-outline-variant hover:text-primary-container transition-colors uppercase">
              Sign up
            </Link>
          </div>
        </form>

      </div>
    </div>
  );
}
