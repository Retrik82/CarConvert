export function formatUsd(value) {
  const num = Number(value);
  if (Number.isNaN(num)) return "$0.00";
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    minimumFractionDigits: 2,
  }).format(num);
}

export function formatDate(value) {
  if (!value) return "";
  return new Intl.DateTimeFormat(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric",
  }).format(new Date(value));
}

export function formatDateTime(value) {
  if (!value) return "";
  return new Intl.DateTimeFormat(undefined, {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  }).format(new Date(value));
}

export function userFacingError(error) {
  if (!error) return "Something went wrong";
  if (typeof error === "string") return error;
  const detail = error.response?.data?.detail;
  if (typeof detail === "string") return detail;
  return error.message || "Something went wrong";
}
