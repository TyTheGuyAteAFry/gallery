import { useState, useEffect } from "react";

export default function Gallery() {
  const [folders, setFolders] = useState(["Vacation", "Family", "Pets"]);
  const [selectedFolder, setSelectedFolder] = useState(folders[0]);
  const [images, setImages] = useState([]);
  const API_URL = import.meta.env.VITE_API_URL; // from .env

  useEffect(() => {
    fetchImages(selectedFolder);
  }, [selectedFolder]);

  async function fetchImages(folder) {
    try {
      const res = await fetch(`${API_URL}/images?folder=${folder}`);
      if (!res.ok) throw new Error("Failed to fetch images");
      const data = await res.json();
      setImages(data.map((item) => item.url));
    } catch (err) {
      console.error(err);
    }
  }

  async function handleUpload(e) {
    const files = Array.from(e.target.files);
    if (!files.length) return;

    // Convert files to base64
    const base64Files = await Promise.all(
      files.map(
        (file) =>
          new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve({ filename: file.name, content: btoa(reader.result) });
            reader.onerror = reject;
            reader.readAsBinaryString(file); // read as binary for base64
          })
      )
    );

    try {
      const res = await fetch(`${API_URL}/upload`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ folder: selectedFolder, files: base64Files }),
      });
      if (!res.ok) throw new Error("Upload failed");
      await fetchImages(selectedFolder); // refresh gallery
    } catch (err) {
      console.error(err);
    }
  }

  return (
    <div className="p-6">
      <h2 className="text-3xl font-bold mb-4 text-center">Gallery</h2>

      <div className="flex justify-between mb-4">
        <select
          className="border p-2 rounded"
          value={selectedFolder}
          onChange={(e) => setSelectedFolder(e.target.value)}
        >
          {folders.map((folder) => (
            <option key={folder} value={folder}>
              {folder}
            </option>
          ))}
        </select>

        <label className="bg-blue-600 text-white px-4 py-2 rounded cursor-pointer hover:bg-blue-700">
          Upload
          <input type="file" multiple onChange={handleUpload} className="hidden" />
        </label>
      </div>

      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        {images.map((src, i) => (
          <img
            key={i}
            src={src}
            alt="uploaded"
            className="w-full h-40 object-cover rounded-lg shadow"
          />
        ))}
      </div>
    </div>
  );
}
