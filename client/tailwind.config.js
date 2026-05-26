/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,jsx}"],
  theme: {
    extend: {
      colors: {
        panel: "rgba(15,23,42,0.58)",
      },
      boxShadow: {
        glow: "0 0 40px rgba(56,189,248,0.16)",
      },
    },
  },
  plugins: [],
};
