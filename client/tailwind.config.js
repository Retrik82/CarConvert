/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,jsx}"],
  theme: {
    extend: {
      colors: {
        brand: {
          50: "#eff6ff",
          100: "#dbeafe",
          200: "#bfdbfe",
          400: "#60a5fa",
          500: "#3b82f6",
          600: "#2563eb",
          700: "#1d4ed8",
        },
        violet: {
          600: "#7c3aed",
        },
        surface: {
          DEFAULT: "#ffffff",
          muted: "#f1f5f9",
          elevated: "#f8fafc",
        },
        ink: {
          DEFAULT: "#0f172a",
          secondary: "#64748b",
          tertiary: "#94a3b8",
        },
      },
      fontFamily: {
        sans: ["Inter", "Segoe UI", "system-ui", "-apple-system", "sans-serif"],
      },
      borderRadius: {
        card: "24px",
        btn: "16px",
        input: "16px",
        chip: "12px",
      },
      boxShadow: {
        card: "0 12px 32px -4px rgba(37, 99, 235, 0.06), 0 2px 8px rgba(15, 23, 42, 0.03)",
        elevated: "0 20px 48px -8px rgba(37, 99, 235, 0.1)",
        button: "0 6px 16px rgba(37, 99, 235, 0.25)",
        glow: "0 0 40px rgba(37, 99, 235, 0.12)",
        glass: "0 8px 32px rgba(15, 23, 42, 0.08)",
      },
      spacing: {
        18: "4.5rem",
        22: "5.5rem",
      },
      animation: {
        "fade-in": "fade-in 0.5s cubic-bezier(0.33, 1, 0.68, 1) forwards",
        "fade-up": "fade-up 0.6s cubic-bezier(0.33, 1, 0.68, 1) forwards",
        "slide-down": "slide-down 0.4s cubic-bezier(0.33, 1, 0.68, 1) forwards",
        shimmer: "shimmer 1.5s ease-in-out infinite",
        float: "float 6s ease-in-out infinite",
        "pulse-soft": "pulse-soft 2s ease-in-out infinite",
      },
      keyframes: {
        "fade-in": {
          from: { opacity: "0" },
          to: { opacity: "1" },
        },
        "fade-up": {
          from: { opacity: "0", transform: "translateY(20px)" },
          to: { opacity: "1", transform: "translateY(0)" },
        },
        "slide-down": {
          from: { opacity: "0", transform: "translateY(-8px)" },
          to: { opacity: "1", transform: "translateY(0)" },
        },
        shimmer: {
          "0%": { backgroundPosition: "-200% 0" },
          "100%": { backgroundPosition: "200% 0" },
        },
        float: {
          "0%, 100%": { transform: "translateY(0)" },
          "50%": { transform: "translateY(-8px)" },
        },
        "pulse-soft": {
          "0%, 100%": { opacity: "1" },
          "50%": { opacity: "0.7" },
        },
      },
      transitionTimingFunction: {
        standard: "cubic-bezier(0.65, 0, 0.35, 1)",
        emphasized: "cubic-bezier(0.33, 1, 0.68, 1)",
      },
      backgroundImage: {
        "gradient-primary": "linear-gradient(135deg, #2563eb 0%, #7c3aed 100%)",
        "gradient-hero": "radial-gradient(circle at 0% 0%, rgba(37, 99, 235, 0.08), transparent 42%), radial-gradient(circle at 100% 0%, rgba(124, 58, 237, 0.06), transparent 38%)",
      },
    },
  },
  plugins: [],
};
