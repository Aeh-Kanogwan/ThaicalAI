// A single item detected in a food photo by a Vision provider.
export interface VisionDetectedItem {
  // Thai label as recognized (used to match against the foods DB keywords).
  label: string;
  confidence: number; // 0..1
  estimatedPortion: string; // e.g. "1 จาน", "0.5 ถ้วย"
  grams: number; // estimated grams for portion sizing
}

export interface VisionResult {
  // Overall confidence for the whole image (max of item confidences typically).
  confidence: number;
  items: VisionDetectedItem[];
}

export interface VisionInput {
  // Raw image bytes (from multipart) or base64 string (from JSON body).
  imageBuffer?: Buffer;
  imageBase64?: string;
  mimeType?: string;
}

export interface VisionProvider {
  readonly name: string;
  detect(input: VisionInput): Promise<VisionResult>;
}
