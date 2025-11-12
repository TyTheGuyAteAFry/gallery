export default function Footer() {
    return (
      <footer className="bg-gray-800 text-gray-100 py-4 mt-8">
        <div className="text-center text-sm">
          © {new Date().getFullYear()} My Gallery — All rights reserved.
        </div>
      </footer>
    );
  }
  