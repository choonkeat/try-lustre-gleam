import { Ok, Error } from "./gleam.mjs"; // this is magic 😬

export function read(key) {
  console.log("ffi.mjs: read", key);
  const value = window.localStorage.getItem(key);
  return value ? new Ok(value) : new Error(undefined);
}
