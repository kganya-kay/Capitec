import { LightningElement, api, track } from "lwc";
import LightningAlert from "lightning/alert";

// Constant: maximum allowed size per file AND total size for all attachments (2 MB)
const MAX_TOTAL_BYTES = 2 * 1024 * 1024; // 2 MB

/**
 * @description LWC for handling email attachments.
 * Supports three sources: template, forwarded, and uploaded files.
 * Enforces per-file and total size limits (2 MB).
 * Displays per-file size and emits change events when attachments are updated.
 */
export default class SendEmailAttachmentUploader extends LightningElement {
  // Internal tracked lists for different attachment sources
  @track _templateAttachments = [];
  @track _forwardedAttachments = [];
  @track _uploadedAttachments = [];

  /**
   * @description Combines all attachment lists into one array for rendering and size checks.
   */
  get attachments() {
    return [
      ...this._templateAttachments,
      ...this._forwardedAttachments,
      ...this._uploadedAttachments
    ];
  }

  /**
   * @description Calculates the total size in bytes of attachments that actually contain fileContent.
   * Forwarded attachments are excluded since they don't hold inline data.
   */
  get totalBytes() {
    return this.attachments.reduce((sum, a) => {
      if (!a || !a.fileContent) return sum;
      return sum + this.base64Bytes(a.fileContent);
    }, 0);
  }

  // ---------- TEMPLATE ATTACHMENTS ----------
  /**
   * @description Normalizes incoming template attachments and enforces total size limit.
   * Accepts as many template files as will fit under the 2 MB limit,
   * and skips only the ones that would exceed the limit.
   */
  @api
  set templateAttachments(value) {
    const incoming = JSON.stringify(value || []);
    const existing = JSON.stringify(this._templateAttachments.map(a => ({ fileName: a.fileName })));
    if (incoming === existing) return;

    // Normalize incoming template attachments (ensure proper fields and size labels)
    const normalized = (value || []).map(att => {
      const rawTitle = att.fileName ?? "Untitled";
      const parts = rawTitle.split(".");
      const extension = parts.length > 1 ? parts.pop().replace(/^\.+/, "").toLowerCase() : "pdf";
      const baseName = parts.join(".");
      const fullFileName = `${baseName}.${extension}`;
      const fileType = extension === "pdf" ? "application/pdf" : null;
      const sizeBytes = att.fileContent ? this.base64Bytes(att.fileContent) : 0;

      return {
        fileContentVersionId: null,
        fileName: fullFileName,
        fileType,
        fileContent: att.fileContent,
        fileContentDocumentId: null,
        source: "template",
        sizeBytes,
        sizeLabel: sizeBytes ? this.formatBytes(sizeBytes) : "—"
      };
    });

    // Already-uploaded files count towards the total
    const uploadedBytes = this._uploadedAttachments.reduce(
      (sum, a) => sum + (a.fileContent ? this.base64Bytes(a.fileContent) : 0),
      0
    );

    const accepted = [];
    const rejectedNames = [];
    let runningTotal = uploadedBytes;

    // Accept template files until size limit is reached; skip the rest
    for (const t of normalized) {
      const size = t.sizeBytes || 0;
      if (runningTotal + size <= MAX_TOTAL_BYTES) {
        accepted.push(t);
        runningTotal += size;
      } else {
        rejectedNames.push(t.fileName);
      }
    }

    this._templateAttachments = accepted;

    // Show alert if some templates were skipped due to size constraints
    if (rejectedNames.length) {
      this.dispatchChangeEvents();
      this.showErrorAlert(
        `The following template file(s) were skipped to keep total ≤ 2 MB: ${rejectedNames.join(", ")}`,
        "Total Size Limit"
      );
      return;
    }

    this.dispatchChangeEvents();
  }

  get templateAttachments() {
    return this._templateAttachments;
  }

  // ---------- FORWARDED ATTACHMENTS ----------
  /**
   * @description Normalizes forwarded attachments.
   * Forwarded files do not contain inline content, so they don’t count toward the size limit.
   */
  @api
  set forwardedAttachments(value) {
    const incoming = JSON.stringify(value || []);
    const existing = JSON.stringify(this._forwardedAttachments.map(a => ({
      fileName: a.fileName,
      fileContentDocumentId: a.fileContentDocumentId
    })));
    if (incoming === existing) return;

    this._forwardedAttachments = (value || []).map(att => ({
      fileContentVersionId: att.fileContentVersionId,
      fileName: att.fileName,
      fileType: att.fileType,
      fileContent: null,
      fileContentDocumentId: att.fileContentDocumentId,
      source: "forwarded",
      sizeBytes: null,
      sizeLabel: "—"
    }));

    this.dispatchChangeEvents();
  }

  get forwardedAttachments() {
    return this._forwardedAttachments;
  }

  // ---------- FILE UPLOAD HANDLER ----------
  /**
   * @description Handles user-selected file uploads.
   * - Rejects non-PDFs
   * - Rejects files > 2 MB
   * - Skips duplicates
   * - Skips only the files that would cause total size to exceed 2 MB
   */
  async handleFileChange(event) {
    const files = Array.from(event.target.files);

    for (const file of files) {
      // Validate PDF format
      if (file.type !== "application/pdf") {
        await this.showErrorAlert(`${file.name} is not a PDF`, "Invalid File");
        continue;
      }

      // Per-file size check (2 MB)
      if (file.size > MAX_TOTAL_BYTES) {
        await this.showErrorAlert(`${file.name} exceeds 2 MB and was not added.`, "File Too Large");
        continue;
      }

      // Duplicate name check
      const isDuplicate = this.attachments.some(a => a.fileName === file.name);
      if (isDuplicate) {
        await this.showErrorAlert(`${file.name} already uploaded`, "Duplicate File");
        continue;
      }

      // Pre-check total size before reading
      if (this.totalBytes + file.size > MAX_TOTAL_BYTES) {
        await this.showErrorAlert(
          `Adding ${file.name} would exceed the 2 MB total limit. It was not added.`,
          "Total Size Limit"
        );
        continue;
      }

      // Read file as base64
      const reader = new FileReader();

      reader.onload = () => {
        if (!this.isConnected) return;

        const base64 = reader.result?.split(",")[1];
        if (!base64) {
          this.showErrorAlert(`Could not extract base64 from ${file.name}`, "Read Error");
          return;
        }

        // Re-check with actual base64 size after reading
        const newBytes = this.base64Bytes(base64);
        if (this.totalBytes + newBytes > MAX_TOTAL_BYTES) {
          this.showErrorAlert(
            `Adding ${file.name} would exceed the 2 MB total limit. It was not added.`,
            "Total Size Limit"
          );
          return;
        }

        // Add new file to uploaded list
        const newAttachment = {
          fileContentVersionId: null,
          fileName: file.name,
          fileContent: base64,
          fileType: file.type,
          fileContentDocumentId: null,
          source: "upload",
          sizeBytes: newBytes,
          sizeLabel: this.formatBytes(newBytes)
        };

        this._uploadedAttachments = [...this._uploadedAttachments, newAttachment];
        this.dispatchChangeEvents();
      };

      reader.onerror = () => {
        this.showErrorAlert(`Unable to read ${file.name}`, "Read Error");
      };

      reader.readAsDataURL(file);
    }
  }

  // ---------- REMOVE FILE ----------
  /**
   * @description Removes a file by name from all attachment sources.
   */
  removeFile(event) {
    const fileName = event.target.dataset.filename;
    this._templateAttachments = this._templateAttachments.filter(f => f.fileName !== fileName);
    this._forwardedAttachments = this._forwardedAttachments.filter(f => f.fileName !== fileName);
    this._uploadedAttachments = this._uploadedAttachments.filter(f => f.fileName !== fileName);
    this.dispatchChangeEvents();
  }

  /**
   * @description Dispatches a custom event with the combined list of attachments.
   */
  dispatchChangeEvents() {
    this.dispatchEvent(new CustomEvent("attachmentschange", {
      detail: this.attachments
    }));
  }

  /**
   * @description Shows a Lightning error alert modal.
   */
  async showErrorAlert(message, label) {
    await LightningAlert.open({
      message,
      theme: "error",
      label
    });
  }

  /**
   * @description Utility: Convert base64 string length to actual byte size.
   */
  base64Bytes(b64) {
    if (!b64) return 0;
    const len = b64.length;
    const padding = b64.endsWith("==") ? 2 : (b64.endsWith("=") ? 1 : 0);
    return Math.floor((len * 3) / 4) - padding;
  }

  /**
   * @description Utility: Format byte count into human-readable text (B, KB, MB).
   */
  formatBytes(bytes) {
    if (bytes == null || isNaN(bytes)) return "—";
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  }
}