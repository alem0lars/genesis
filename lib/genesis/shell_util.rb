class Array
  def each_exec
    each do |cmd|
      system cmd
      break unless $?.success?
    end
    $?.success?
  end
end
