import { Link } from "react-router-dom";

export default function Home() {
  return (
    <section className="text-center py-12">
      <h2 className="text-4xl font-bold mb-4">Welcome to My Gallery App</h2>
      <p className="text-gray-600 mb-6">
        Upload, organize, and share your photos — all in one place.
      </p>

      <div className="space-x-4">
        <Link
          to="/gallery"
          className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700"
        >
          View Gallery
        </Link>
        <Link
          to="/login"
          className="bg-gray-200 text-gray-700 px-4 py-2 rounded hover:bg-gray-300"
        >
          Login
        </Link>
      </div>

      <div className="mt-12 grid grid-cols-1 sm:grid-cols-3 gap-6 px-6 max-w-5xl mx-auto">
        <Feature title="📂 Folder Sorting" text="Organize your photos into folders." />
        <Feature title="☁️ Cloud Uploads" text="Upload securely to AWS S3." />
        <Feature title="🧑‍💻 Secure Login" text="Protect your gallery with authentication." />
      </div>
    </section>
  );
}

function Feature({ title, text }) {
  return (
    <div className="p-6 bg-white rounded-lg shadow">
      <h3 className="text-lg font-semibold mb-2">{title}</h3>
      <p className="text-gray-600">{text}</p>
    </div>
  );
}
