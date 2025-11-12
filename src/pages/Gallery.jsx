import { useState } from "react";

export default function Gallery() {
  const [folders, setFolders] = useState(["Vacation", "Family", "Pets"]);
  const [images, setImages] = useState([]);

  function handleUpload(e) {
    const files = Array.from(e.target.files);
    setImages((prev) => [...prev, ...files.map((f) => URL.createObjectURL(f))]);
  }

  return (
    <div className="p-6">
      <h2 className="text-3xl font-bold mb-4 text-center">Gallery</h2>

      <div className="flex justify-between mb-4">
        <select className="border p-2 rounded">
          {folders.map((folder) => (
            <option key={folder}>{folder}</option>
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
            alt="upload"
            className="w-full h-40 object-cover rounded-lg shadow"
          />
        ))}
      </div>
    </div>
  );
}
