export default function Contact() {
    return (
      <div className="p-8 text-center">
        <h2 className="text-3xl font-bold mb-4">Contact Us</h2>
        <p className="text-gray-600 mb-6">
          Have questions? Reach out and we’ll get back to you soon.
        </p>
  
        <form className="max-w-md mx-auto">
          <input
            type="text"
            placeholder="Name"
            className="w-full border p-2 mb-4 rounded"
          />
          <input
            type="email"
            placeholder="Email"
            className="w-full border p-2 mb-4 rounded"
          />
          <textarea
            placeholder="Message"
            className="w-full border p-2 mb-4 rounded"
          ></textarea>
          <button className="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700">
            Send
          </button>
        </form>
      </div>
    );
  }
  