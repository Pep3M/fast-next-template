const handleResponse = async <T>(response: Response) => {
  if (!response.ok) {
    throw new Error(response.statusText);
  }
  return response.json() as Promise<T>;
}

export const fetcher = async <T>(url: string) => {
  const res = await fetch(url);
  return handleResponse<T>(res);
};
