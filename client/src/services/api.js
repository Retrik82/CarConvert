import { imageEditRepository } from "../repositories/imageEditRepository.js";
import httpClient from "../api/httpClient.js";

/** @deprecated Use imageEditRepository instead. */
export async function editImage(params) {
  return imageEditRepository.editImage(params);
}

/** @deprecated Use httpClient from api/httpClient.js instead. */
export default httpClient;
