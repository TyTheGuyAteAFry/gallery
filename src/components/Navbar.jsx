import { Link } from "react-router-dom";

export default function Navbar() {
  return (
    <nav className="bg-white shadow-md">
      <div className="container mx-auto px-4 py-3 flex justify-between items-center">
        <h1 className="text-xl font-bold text-blue-600">📸 My Gallery</h1>
        <div className="space-x-4">
          <Link className="hover:text-blue-600" to="/">Home</Link>
          <Link className="hover:text-blue-600" to="/gallery">Gallery</Link>
          <Link className="hover:text-blue-600" to="/contact">Contact</Link>
          <Link className="hover:text-blue-600" to="/login">Login</Link>
        </div>
      </div>
    </nav>
  );
}
