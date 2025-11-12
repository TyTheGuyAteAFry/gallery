import { useState, useEffect } from "react";
import GalleryGrid from "../components/GalleryGrid";
import UploadModal from "../components/UploadModal";
import apiClient from "../api/apiClient";

export default function Gallery() {
  const [folders, setFolders] = useState([]);
  const [selectedFolder, setSelectedFolder] = useState(null);

  useEffect(() => {
    apiClient.get("/folders").then((res) => setFolders(res.data));
  }, []);

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold">Your Gallery</h1>
      <select
        onChange={(e) => setSelectedFolder(e.target.value)}
        className="border rounded p-2"
      >
        <option value="">Select folder</option>
        {folders.map((f) => (
          <option key={f.id} value={f.id}>{f.name}</option>
        ))}
      </select>

      {selectedFolder && <GalleryGrid folderId={selectedFolder} />}

      <UploadModal selectedFolder={selectedFolder} />
    </div>
  );
}
